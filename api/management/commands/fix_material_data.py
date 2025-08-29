from django.core.management.base import BaseCommand
from api.models import Material

class Command(BaseCommand):
    help = 'Finds and removes orphaned materials (materials not linked to a company).'

    def handle(self, *args, **options):
        orphaned_materials = Material.objects.filter(company__isnull=True)
        count = orphaned_materials.count()

        if count == 0:
            self.stdout.write(self.style.SUCCESS('No orphaned materials found. Your database looks clean!'))
            return

        self.stdout.write(self.style.WARNING(f'Found {count} orphaned material(s).'))

        # Ask for confirmation before deleting
        response = input('Are you sure you want to delete these materials? (yes/no): ')
        if response.lower() != 'yes':
            self.stdout.write(self.style.ERROR('Operation cancelled by user.'))
            return

        orphaned_materials.delete()
        self.stdout.write(self.style.SUCCESS(f'Successfully deleted {count} orphaned material(s).'))
