from rest_framework import serializers
from .models import Product, Material, ProductMaterialMapping, ProductionOrder, InwardEntry

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ['id', 'name']

class MaterialSerializer(serializers.ModelSerializer):
    class Meta:
        model = Material
        fields = ['id', 'name', 'style', 'unit', 'quantity', 'low_stock_threshold']

class ProductMaterialMappingSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductMaterialMapping
        fields = ['id', 'product', 'material', 'fixed_quantity']


class ProductionOrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductionOrder
        fields = ['id', 'product', 'quantity', 'created_at']

class InwardEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = InwardEntry
        fields = ['id', 'material', 'quantity', 'created_at']
        read_only_fields = ['created_at']
