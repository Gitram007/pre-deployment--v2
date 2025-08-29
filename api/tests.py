from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from django.contrib.auth.models import User
from .models import Company, UserProfile, Product, Material, ProductMaterialMapping

class CoreApiTests(APITestCase):
    def setUp(self):
        # Create a company
        self.company = Company.objects.create(name="Test Company")

        # Create an admin user
        self.admin_user = User.objects.create_user(username='admin', password='password123')
        self.admin_profile = UserProfile.objects.create(user=self.admin_user, company=self.company, role='admin')

        # Create a staff user
        self.staff_user = User.objects.create_user(username='staff', password='password123')
        self.staff_profile = UserProfile.objects.create(user=self.staff_user, company=self.company, role='staff')

        # Create some initial data
        self.product = Product.objects.create(company=self.company, name='Test Product')
        self.material = Material.objects.create(company=self.company, name='Test Material', unit='kg', quantity=50, low_stock_threshold=10)

    def test_unauthenticated_access_is_denied(self):
        """
        Ensure unauthenticated users cannot access protected endpoints.
        """
        url = reverse('product-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

        url = reverse('product-detail', kwargs={'pk': self.product.pk})
        response = self.client.post(url, {'name': 'New Name'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_staff_user_has_read_only_access(self):
        """
        Ensure staff users can read data but cannot create, update, or delete.
        """
        self.client.force_authenticate(user=self.staff_user)

        # Staff can LIST products
        url = reverse('product-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        # Staff CANNOT CREATE products
        response = self.client.post(url, {'name': 'Staff Product'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Staff CANNOT UPDATE products
        url = reverse('product-detail', kwargs={'pk': self.product.pk})
        response = self.client.put(url, {'name': 'Updated Name'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Staff CANNOT DELETE products
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_user_has_full_access(self):
        """
        Ensure admin users have full CRUD access.
        """
        self.client.force_authenticate(user=self.admin_user)

        # Admin can LIST products
        url = reverse('product-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Admin CAN CREATE products
        response = self.client.post(url, {'name': 'Admin Product'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Product.objects.count(), 2)

        # Admin CAN UPDATE products
        product_to_update = Product.objects.get(name='Admin Product')
        url = reverse('product-detail', kwargs={'pk': product_to_update.pk})
        response = self.client.put(url, {'name': 'Updated Name'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        product_to_update.refresh_from_db()
        self.assertEqual(product_to_update.name, 'Updated Name')

        # Admin CAN DELETE products
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Product.objects.count(), 1)

    def test_dashboard_and_low_stock_endpoints(self):
        """
        Ensure dashboard and low-stock endpoints are accessible and return correct data.
        """
        # Create a material that is low on stock
        Material.objects.create(
            company=self.company, name='Low Stock Material', unit='pcs', quantity=5, low_stock_threshold=20
        )
        # Create a material that is not low on stock
        Material.objects.create(
            company=self.company, name='High Stock Material', unit='pcs', quantity=100, low_stock_threshold=20
        )

        self.client.force_authenticate(user=self.staff_user)

        # Test dashboard endpoint
        url = reverse('dashboard-data')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('product_count', response.data)
        self.assertIn('material_count', response.data)
        self.assertIn('low_stock_materials', response.data)
        self.assertEqual(response.data['product_count'], 1)
        self.assertEqual(response.data['material_count'], 3)
        # The dashboard view itself also filters for low stock
        self.assertEqual(len(response.data['low_stock_materials']), 1)

        # Test low-stock-materials endpoint
        url = reverse('lowstockmaterial-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsInstance(response.data, list)
        # There is 1 low stock material from this test
        self.assertEqual(len(response.data), 1)
        low_stock_names = [item['name'] for item in response.data]
        self.assertNotIn('Test Material', low_stock_names)
        self.assertIn('Low Stock Material', low_stock_names)
        self.assertNotIn('High Stock Material', low_stock_names)

    def test_duplicate_product_creation_is_prevented(self):
        """
        Ensure that creating a product with a duplicate name within the same company fails.
        """
        self.client.force_authenticate(user=self.admin_user)
        url = reverse('product-list')
        # This product name already exists from the CoreApiTests setUp
        data = {'name': 'Test Product'}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_duplicate_material_creation_is_prevented(self):
        """
        Ensure that creating a material with a duplicate name within the same company fails.
        """
        self.client.force_authenticate(user=self.admin_user)
        url = reverse('material-list')
        # This material name already exists from the CoreApiTests setUp
        data = {'name': 'Test Material', 'unit': 'kg', 'quantity': 10}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class UserManagementApiTests(APITestCase):
    def setUp(self):
        self.company = Company.objects.create(name="User Test Corp")
        self.admin_user = User.objects.create_user(username='testadmin', password='password123')
        UserProfile.objects.create(user=self.admin_user, company=self.company, role='admin')

        self.staff_user = User.objects.create_user(username='teststaff', password='password123')
        UserProfile.objects.create(user=self.staff_user, company=self.company, role='staff')

    def test_admin_can_list_users(self):
        """
        Ensure admin users can list all users in their company.
        """
        self.client.force_authenticate(user=self.admin_user)
        url = reverse('user-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # setUp creates 2 users
        self.assertEqual(len(response.data), 2)

    def test_staff_cannot_list_users(self):
        """
        Ensure staff users are forbidden from listing users.
        """
        self.client.force_authenticate(user=self.staff_user)
        url = reverse('user-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_can_create_user(self):
        """
        Ensure admin users can create new users.
        """
        self.client.force_authenticate(user=self.admin_user)
        url = reverse('admin-create-user')
        data = {
            'username': 'newuser',
            'password': 'newpassword123',
            'email': 'newuser@example.com',
            'role': 'staff'
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(User.objects.count(), 3)
        new_user = User.objects.get(username='newuser')
        self.assertEqual(new_user.profile.role, 'staff')

    def test_staff_cannot_create_user(self):
        """
        Ensure staff users cannot create new users.
        """
        self.client.force_authenticate(user=self.staff_user)
        url = reverse('admin-create-user')
        data = {'username': 'newuser', 'password': 'password123', 'role': 'staff'}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class CalculatorApiTests(APITestCase):
    def setUp(self):
        self.company = Company.objects.create(name="Calc Test Corp")
        self.admin_user = User.objects.create_user(username='calcadmin', password='password123')
        UserProfile.objects.create(user=self.admin_user, company=self.company, role='admin')

        self.product = Product.objects.create(company=self.company, name='Test Calc Product')
        self.material = Material.objects.create(
            company=self.company, name='Test Calc Material', unit='g', quantity=100, low_stock_threshold=10
        )
        # Mapping: 1 product requires 10g of material
        self.mapping = ProductMaterialMapping.objects.create(
            company=self.company, product=self.product, material=self.material, fixed_quantity=10.5
        )

    def test_calculator_success(self):
        """
        Ensure the calculator returns correct results with correct data types.
        """
        self.client.force_authenticate(user=self.admin_user)
        url = reverse('material-calculator')
        data = {'product_id': self.product.pk, 'quantity': 5}
        response = self.client.post(url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsInstance(response.data, list)
        self.assertEqual(len(response.data), 1)

        result = response.data[0]
        self.assertEqual(result['material_name'], 'Test Calc Material')
        self.assertEqual(result['required_quantity'], 52.5) # 10.5 * 5
        self.assertEqual(result['current_stock'], 100.0)
        self.assertEqual(result['shortfall'], 0.0)

        # Verify data types are float, not string
        self.assertIsInstance(result['required_quantity'], float)
        self.assertIsInstance(result['current_stock'], float)
        self.assertIsInstance(result['shortfall'], float)

    def test_product_with_same_name_in_different_company_succeeds(self):
        """
        Ensure a product with the same name as one in another company can be created.
        """
        self.client.force_authenticate(user=self.admin_user)
        url = reverse('product-list')
        # This product name exists in the company created in CoreApiTests
        data = {'name': 'Test Product'}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_material_with_same_name_in_different_company_succeeds(self):
        """
        Ensure a material with the same name as one in another company can be created.
        """
        self.client.force_authenticate(user=self.admin_user)
        url = reverse('material-list')
        # This material name exists in the company created in CoreApiTests
        data = {'name': 'Test Material', 'unit': 'kg', 'quantity': 10}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_calculator_with_shortfall(self):
        """
        Ensure the calculator correctly identifies a shortfall.
        """
        self.client.force_authenticate(user=self.admin_user)
        url = reverse('material-calculator')
        data = {'product_id': self.product.pk, 'quantity': 10} # Requires 105g, we have 100g
        response = self.client.post(url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        result = response.data[0]
        self.assertEqual(result['required_quantity'], 105.0)
        self.assertEqual(result['current_stock'], 100.0)
        self.assertEqual(result['shortfall'], 5.0)
        self.assertIsInstance(result['shortfall'], float)
