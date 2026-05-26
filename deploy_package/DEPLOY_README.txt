# Backend Deployment Instructions (Baota / BT-Panel)

Please follow these steps to deploy the Cloud Hosting backend:

1. Log in to your Baota Control Panel.
2. Go to "Files" and navigate to your website root: `/www/wwwroot/page.niceapp.eu.cc/apps/code_editor/share/`.
3. Create a folder named `api`.
4. Create a folder named `pub` (and ensure it has write permissions: 755).
5. Upload the `publish.php` file from your local `backend/` folder to the `api/` folder on the server.
6. Upload the `admin.php` file from your local `backend/` folder to the `api/` folder on the server.
7. Upload the `redirect.php` file to the website root or configure URL rewrite rules.

The final structure on your server should look like this:
/www/wwwroot/page.niceapp.eu.cc/apps/code_editor/share/
├── api/
│   ├── publish.php
│   └── admin.php
└── pub/
    └── (published projects will appear here)

Your public API URL will be: https://page.niceapp.eu.cc/apps/code_editor/share/api/publish.php
Your admin panel URL will be: https://page.niceapp.eu.cc/apps/code_editor/share/api/admin.php?key=admin_2024_secret_key
Your published projects will be accessible at: https://page.niceapp.eu.cc/apps/code_editor/share/pub/[id]/index.html

# Admin Panel Features

1. View all published links with project info, visit counts, and status
2. Search and sort links by name, visits, creation date
3. Bulk delete links
4. Domain switching (when domain is blocked, update all links at once)
5. Individual link statistics with 7-day visit trends

# Security Note

Please change the default admin key in admin.php before deploying:
```php
'admin_key' => 'admin_2024_secret_key',  // Change this to a strong password
```
