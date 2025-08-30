from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ProductViewSet,
    MaterialViewSet,
    ProductMaterialMappingViewSet,
    ProductionOrderViewSet,
    InwardEntryViewSet,
    LowStockMaterialViewSet,
    material_usage_by_product,
    overall_report,
    dashboard_data,
    material_calculator
)
from .user_views import RegisterView, AdminUserCreateView, UserListView, UserDetailView

router = DefaultRouter()
router.register(r'products', ProductViewSet, basename='product')
router.register(r'materials', MaterialViewSet, basename='material')
router.register(r'mappings', ProductMaterialMappingViewSet, basename='productmaterialmapping')
router.register(r'production-orders', ProductionOrderViewSet, basename='productionorder')
router.register(r'inward-entries', InwardEntryViewSet, basename='inwardentry')
router.register(r'low-stock-materials', LowStockMaterialViewSet, basename='lowstockmaterial')

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('users/create/', AdminUserCreateView.as_view(), name='admin-create-user'),
    path('users/<int:pk>/', UserDetailView.as_view(), name='user-detail'),
    path('users/', UserListView.as_view(), name='user-list'),
    path('', include(router.urls)),
    path('dashboard/', dashboard_data, name='dashboard-data'),
    path('calculator/', material_calculator, name='material-calculator'),
    path('reports/material-usage/<int:product_id>/', material_usage_by_product, name='material-usage-by-product'),
    path('reports/overall-report/', overall_report, name='overall-report'),
]
