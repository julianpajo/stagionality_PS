# TUTORIAL

## Verify Services Health

After deploying the stacks, wait until all Docker services are running and healthy.

You can verify this by checking the status with the following command:

```bash
docker ps
```

## Download Data

Once the euler_db-ps service is up and healthy you can upload the data.

To download the data and upload it into your database, you can execute the script provided.

```bash
cd /path/to/project/stagionality_PS/services/db_ps/scripts
. import_data.sh
```

## Access the Services

Once all services are healthy, you can access them using your preferred browser.

To use the services, since the deployment uses self-signed certificates, you need to add the Certificate Authority (CA) to your browser.

For example, in Chrome:

- Go to Settings
- Navigate to **Privacy and security**
- Select **Manage certificates**
- Go to the **Authorities tab**
- Import the `myCA.pem` file located at **/path/to/project/stagionality_PS/deployment/certificates/myCA.pem**


The services you can access are:

- **Traefik**: euler.local/dashboard/
- **Keycloak**: keycloak.euler.local/auth
- **GeoServer**: geoserver.euler.local/geoserver
- **Displacement**: displacement.euler.local

### Traefik

In the Traefik dashboard, you can monitor and manage your network traffic, view the status of your services, and configure routing rules.

In the Traefik dashboard, you should be able to view the status of the deployed routers and services. Therefore:

- **Routers**: 6 Successful
- **Services**: 7 Successful
- **Middlewares**: 1 Successful

If this is the case, then the services have been deployed correctly and Traefik is able to resolve them.

### Keycloak

In Keycloak, you can manage user authentication and authorization, configure identity providers, and administer user roles and permissions.

You can access the admin dashboard with the credentials:
- username: **admin**
- password: the value of the secret **keycloak_admin_passwd**

### Geoserver

In GeoServer, you can manage spatial data, create and publish geospatial services, and configure layers and styles for mapping applications. 

Here's how you can set up GeoServer correctly, presented in a structured format:

#### Accessing the Admin Dashboard
To access the admin dashboard, use the credentials:
- **Username**: kartoza
- **Password**: password

#### Step-by-Step Setup Guide

1. **Creating a New Workspace**
   - Navigate to `Data -> Workspaces`
   - Select `Add new workspace`
   - Enter the following details:
     - **Name**: euler
     - **Namespace URI**: `http://geoserver.org/euler`
   - Click `Save`

2. **Adding a New Store**
   - Go to `Data -> Stores`
   - Choose `Add new store`
   - Select `PostGIS - PostGIS Database`
   - Connect to your database with these settings:
     - **Workspace**: euler
     - **Data Source Name**: euler
     - **Host**: db-ps
     - **Port**: 5432
     - **Database**: EULER
     - **Schema**: EULER
     - **User**: postgres
     - **Password**: (use the value from the secret `postgres_passwd`)
   - Leave the other settings as default.

3. **Publishing a Layer**
   - After saving the store, you'll be directed to the `Layers` page.
   - Publish the `ps_measurements` layer.

4. **Editing Layer Settings**
   - On the `Edit Layer` page, fill in the fields as follows:
     - **Native SRS**: EPSG:3857
     - **Declared SRS**: EPSG:4326
     - **SRS Handling**: Keep native
   - Ensure the `Native` and `Lat/Lon Bounding Box` have identical values:
     - **Min X**: 16.827504
     - **Min Y**: 41.086901
     - **Max X**: 16.899167
     - **Max Y**: 41.147934
   - Click `Apply`.

5. **Defining Styles**
   - Navigate to `Data -> Styles`
   - Click `Add new style`
   - Input the following details:
     - **Name**: euler
     - **Workspace**: euler
     - **Format**: SLD
     - **Upload a style file**: navigate to the SLD file path **/path/to/project/stagionality_PS/deployment/swarm/config/geoserver/SLD.txt**
   - Click `Upload`, then `Validate` to check for errors.
   - If no validation errors occur, click `Save`.

6. **Applying Styles to the Layer**
   - Return to `Data -> Layers` and select `ps_measurements`
   - In the `Publishing` section, set:
     - **Default Style**: euler:euler
   - In `Available Styles`, double-click on `euler:euler` to move it to `Selected Styles`
   - Click `Save`.

By following these steps, you should have a properly configured GeoServer instance ready for managing and publishing your geospatial data. Remember to replace placeholder paths and credentials with your actual data.


