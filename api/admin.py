from django.contrib import admin
from .models import Company, UserProfile, Product, Material, ProductMaterialMapping, ProductionOrder, InwardEntry

@admin.register(Company)
class CompanyAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_at')
    search_fields = ('name',)

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'company', 'role')
    list_filter = ('role', 'company')
    search_fields = ('user__username', 'company__name')
    raw_id_fields = ('user', 'company')

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'company')
    list_filter = ('company',)
    search_fields = ('name', 'company__name')

@admin.register(Material)
class MaterialAdmin(admin.ModelAdmin):
    list_display = ('name', 'quantity', 'unit', 'style', 'company')
    list_filter = ('company', 'style')
    search_fields = ('name', 'company__name', 'style')

@admin.register(ProductMaterialMapping)
class ProductMaterialMappingAdmin(admin.ModelAdmin):
    list_display = ('product', 'material', 'fixed_quantity', 'company')
    list_filter = ('company',)
    search_fields = ('product__name', 'material__name', 'company__name')

@admin.register(ProductionOrder)
class ProductionOrderAdmin(admin.ModelAdmin):
    list_display = ('product', 'quantity', 'created_at', 'company')
    list_filter = ('company', 'created_at')
    search_fields = ('product__name', 'company__name')

@admin.register(InwardEntry)
class InwardEntryAdmin(admin.ModelAdmin):
    list_display = ('material', 'quantity', 'created_at', 'company')
    list_filter = ('company', 'created_at')
    search_fields = ('material__name', 'company__name')
