from datetime import timedelta
from django.db import transaction
from django.utils import timezone
from rest_framework import viewsets, status, serializers
from rest_framework.decorators import api_view, permission_classes as api_permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import F
from .models import Product, Material, ProductMaterialMapping, ProductionOrder, InwardEntry
from .serializers import ProductSerializer, MaterialSerializer, ProductMaterialMappingSerializer, ProductionOrderSerializer, InwardEntrySerializer
from .permissions import IsAdminUser

class LowStockMaterialViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that allows viewing of materials that are low on stock.
    """
    serializer_class = MaterialSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        This view should return a list of all materials for the user's company
        where the quantity is less than or equal to the low_stock_threshold.
        """
        try:
            user_company = self.request.user.profile.company
            return Material.objects.filter(
                company=user_company,
                quantity__lte=F('low_stock_threshold')
            )
        except AttributeError:
            # Handle cases where user has no profile (e.g., superuser) or no company
            return Material.objects.none()

class ProductViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows products to be viewed or edited.
    """
    serializer_class = ProductSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            self.permission_classes = [IsAuthenticated]
        else:
            self.permission_classes = [IsAdminUser]
        return super().get_permissions()

    def get_queryset(self):
        """
        This view should return a list of all the products
        for the currently authenticated user's company.
        """
        try:
            return Product.objects.filter(
                company=self.request.user.profile.company,
                company__isnull=False
            )
        except AttributeError:
            return Product.objects.none()

    def perform_create(self, serializer):
        if hasattr(self.request.user, 'profile'):
            serializer.save(company=self.request.user.profile.company)
        else:
            raise serializers.ValidationError("Admin user cannot create company-specific resources.")

class InwardEntryViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows inward entries to be viewed or edited.
    """
    serializer_class = InwardEntrySerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve', 'create']:
            self.permission_classes = [IsAuthenticated]
        else:
            self.permission_classes = [IsAdminUser]
        return super().get_permissions()

    def get_queryset(self):
        try:
            return InwardEntry.objects.filter(
                company=self.request.user.profile.company,
                company__isnull=False
            )
        except AttributeError:
            return InwardEntry.objects.none()

    def perform_create(self, serializer):
        if hasattr(self.request.user, 'profile'):
            inward_entry = serializer.save(company=self.request.user.profile.company)
            material = inward_entry.material
            material.quantity += inward_entry.quantity
            material.save()
        else:
            raise serializers.ValidationError("Admin user cannot create company-specific resources.")

class MaterialViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows materials to be viewed or edited.
    """
    serializer_class = MaterialSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            self.permission_classes = [IsAuthenticated]
        else:
            self.permission_classes = [IsAdminUser]
        return super().get_permissions()

    def get_queryset(self):
        try:
            return Material.objects.filter(
                company=self.request.user.profile.company,
                company__isnull=False
            )
        except AttributeError:
            return Material.objects.none()

    def perform_create(self, serializer):
        if hasattr(self.request.user, 'profile'):
            serializer.save(company=self.request.user.profile.company)
        else:
            raise serializers.ValidationError("Admin user cannot create company-specific resources.")

class ProductMaterialMappingViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows product-material mappings to be viewed or edited.
    """
    serializer_class = ProductMaterialMappingSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            self.permission_classes = [IsAuthenticated]
        else:
            self.permission_classes = [IsAdminUser]
        return super().get_permissions()

    def get_queryset(self):
        try:
            return ProductMaterialMapping.objects.filter(
                company=self.request.user.profile.company,
                company__isnull=False
            )
        except AttributeError:
            return ProductMaterialMapping.objects.none()

    def perform_create(self, serializer):
        if hasattr(self.request.user, 'profile'):
            serializer.save(company=self.request.user.profile.company)
        else:
            raise serializers.ValidationError("Admin user cannot create company-specific resources.")

class ProductionOrderViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows production orders to be viewed or edited.
    """
    serializer_class = ProductionOrderSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve', 'create']:
            self.permission_classes = [IsAuthenticated]
        else:
            self.permission_classes = [IsAdminUser]
        return super().get_permissions()

    def get_queryset(self):
        try:
            return ProductionOrder.objects.filter(
                company=self.request.user.profile.company,
                company__isnull=False
            )
        except AttributeError:
            return ProductionOrder.objects.none()

    def perform_create(self, serializer):
        if not hasattr(self.request.user, 'profile'):
            raise serializers.ValidationError("Admin user cannot create company-specific resources.")

        product = serializer.validated_data['product']
        quantity = serializer.validated_data['quantity']
        mappings = ProductMaterialMapping.objects.filter(product=product)

        # Check for sufficient materials
        for mapping in mappings:
            required_quantity = mapping.fixed_quantity * quantity
            if mapping.material.quantity < required_quantity:
                raise serializers.ValidationError(
                    f"Not enough {mapping.material.name} in stock. "
                    f"Required: {required_quantity}, Available: {mapping.material.quantity}"
                )

        # Deduct materials and save the order
        with transaction.atomic():
            for mapping in mappings:
                mapping.material.quantity -= mapping.fixed_quantity * quantity
                mapping.material.save()

            serializer.save(company=self.request.user.profile.company)

@api_view(['GET'])
@api_permission_classes([IsAuthenticated])
def dashboard_data(request):
    """
    Provides a consolidated set of data for the main dashboard.
    """
    try:
        user = request.user
        company = user.profile.company

        # Key Metrics
        product_count = Product.objects.filter(company=company).count()
        material_count = Material.objects.filter(company=company).count()

        # Low Stock Materials
        low_stock_materials = Material.objects.filter(
            company=company,
            quantity__lte=F('low_stock_threshold')
        )
        low_stock_serializer = MaterialSerializer(low_stock_materials, many=True)

        # Recent Activity
        recent_production_orders = ProductionOrder.objects.filter(company=company).order_by('-created_at')[:5]
        production_serializer = ProductionOrderSerializer(recent_production_orders, many=True)

        recent_inward_entries = InwardEntry.objects.filter(company=company).order_by('-created_at')[:5]
        inward_serializer = InwardEntrySerializer(recent_inward_entries, many=True)

        data = {
            'product_count': product_count,
            'material_count': material_count,
            'low_stock_materials': low_stock_serializer.data,
            'recent_production_orders': production_serializer.data,
            'recent_inward_entries': inward_serializer.data,
        }
        return Response(data)

    except AttributeError:
        # Handle cases where user has no profile (e.g., superuser)
        return Response({
            'product_count': 0,
            'material_count': 0,
            'low_stock_materials': [],
            'recent_production_orders': [],
            'recent_inward_entries': [],
        })

@api_view(['GET'])
@api_permission_classes([IsAuthenticated])
def material_usage_by_product(request, product_id):
    """
    Calculates material usage for a specific product based on production orders.
    Query parameters:
    - frequency: 'daily', 'weekly', or 'monthly'
    """
    try:
        # Ensure the product belongs to the user's company
        product = Product.objects.get(pk=product_id, company=request.user.profile.company)
    except Product.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

    frequency = request.query_params.get('frequency', 'daily').lower()
    now = timezone.now()
    if frequency == 'daily':
        start_date = now - timedelta(days=1)
    elif frequency == 'weekly':
        start_date = now - timedelta(weeks=1)
    elif frequency == 'monthly':
        start_date = now - timedelta(days=30) # approximation
    else:
        return Response({'error': 'Invalid frequency parameter'}, status=status.HTTP_400_BAD_REQUEST)

    production_orders = ProductionOrder.objects.filter(
        company=request.user.profile.company,
        product=product,
        created_at__gte=start_date
    )

    material_usage = {}
    for order in production_orders:
        mappings = ProductMaterialMapping.objects.filter(product=order.product)
        for mapping in mappings:
            material_name = mapping.material.name
            usage = mapping.fixed_quantity * order.quantity
            material_usage[material_name] = material_usage.get(material_name, 0) + usage

    return Response(material_usage)


@api_view(['POST'])
@api_permission_classes([IsAuthenticated])
def material_calculator(request):
    """
    Calculates the required materials, current stock, and shortfall for producing a given quantity of a product.
    """
    try:
        product_id = request.data.get('product_id')
        quantity_to_produce = request.data.get('quantity')

        if not product_id or quantity_to_produce is None:
            return Response({'error': 'product_id and quantity are required.'}, status=status.HTTP_400_BAD_REQUEST)

        quantity_to_produce = int(quantity_to_produce)
        if quantity_to_produce <= 0:
            return Response({'error': 'Quantity must be a positive integer.'}, status=status.HTTP_400_BAD_REQUEST)

        user_company = request.user.profile.company
        product = Product.objects.get(pk=product_id, company=user_company)

        mappings = ProductMaterialMapping.objects.filter(product=product)
        if not mappings.exists():
            return Response({'error': 'No material mappings found for this product.'}, status=status.HTTP_404_NOT_FOUND)

        results = []
        for mapping in mappings:
            material = mapping.material
            required_quantity = mapping.fixed_quantity * quantity_to_produce
            current_stock = material.quantity
            shortfall = max(0, required_quantity - current_stock)

            results.append({
                'material_id': material.id,
                'material_name': material.name,
                'material_unit': material.unit,
                'required_quantity': float(required_quantity),
                'current_stock': float(current_stock),
                'shortfall': float(shortfall),
            })

        return Response(results)

    except Product.DoesNotExist:
        return Response({'error': 'Product not found in your company.'}, status=status.HTTP_404_NOT_FOUND)
    except ValueError:
        return Response({'error': 'Invalid quantity provided. Must be an integer.'}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@api_permission_classes([IsAuthenticated])
def overall_report(request):
    """
    Calculates the overall report of material inward vs. usage.
    Query parameters:
    - frequency: 'daily', 'weekly', or 'monthly'
    """
    frequency = request.query_params.get('frequency', 'daily').lower()
    now = timezone.now()
    if frequency == 'daily':
        start_date = now - timedelta(days=1)
    elif frequency == 'weekly':
        start_date = now - timedelta(weeks=1)
    elif frequency == 'monthly':
        start_date = now - timedelta(days=30) # approximation
    else:
        return Response({'error': 'Invalid frequency parameter'}, status=status.HTTP_400_BAD_REQUEST)

    # Calculate total inward quantity
    inward_entries = InwardEntry.objects.filter(
        company=request.user.profile.company,
        created_at__gte=start_date
    )
    inward_quantity = {}
    for entry in inward_entries:
        material_name = entry.material.name
        inward_quantity[material_name] = inward_quantity.get(material_name, 0) + entry.quantity

    # Calculate total material usage
    production_orders = ProductionOrder.objects.filter(
        company=request.user.profile.company,
        created_at__gte=start_date
    )
    material_usage = {}
    for order in production_orders:
        mappings = ProductMaterialMapping.objects.filter(product=order.product)
        for mapping in mappings:
            material_name = mapping.material.name
            usage = mapping.fixed_quantity * order.quantity
            material_usage[material_name] = material_usage.get(material_name, 0) + usage

    # Calculate the overall report
    overall_report = {}
    all_materials = set(inward_quantity.keys()) | set(material_usage.keys())
    for material in all_materials:
        inward = inward_quantity.get(material, 0)
        usage = material_usage.get(material, 0)
        overall_report[material] = {
            'inward': inward,
            'usage': usage,
            'balance': inward - usage
        }

    return Response(overall_report)

@api_view(['GET'])
@api_permission_classes([IsAuthenticated])
def overall_material_usage(request):
    """
    Calculates overall material usage across all products based on production orders.
    Query parameters:
    - frequency: 'daily', 'weekly', or 'monthly'
    """
    frequency = request.query_params.get('frequency', 'daily').lower()
    now = timezone.now()
    if frequency == 'daily':
        start_date = now - timedelta(days=1)
    elif frequency == 'weekly':
        start_date = now - timedelta(weeks=1)
    elif frequency == 'monthly':
        start_date = now - timedelta(days=30) # approximation
    else:
        return Response({'error': 'Invalid frequency parameter'}, status=status.HTTP_400_BAD_REQUEST)

    production_orders = ProductionOrder.objects.filter(
        company=request.user.profile.company,
        created_at__gte=start_date
    )

    material_usage = {}
    for order in production_orders:
        mappings = ProductMaterialMapping.objects.filter(product=order.product)
        for mapping in mappings:
            material_name = mapping.material.name
            usage = mapping.fixed_quantity * order.quantity
            material_usage[material_name] = material_usage.get(material_name, 0) + usage

    return Response(material_usage)
