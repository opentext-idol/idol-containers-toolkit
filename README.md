# IDOL Container Toolkit

This is a collection of tools to allow you to set up and use simple IDOL Docker systems. 
It consists of a directories of Docker compose files, plus (where required) build contexts 
for the servers used in the systems.

The container images used by the system are available from a private Docker Hub 
repository (_microfocusidolserver_). Please contact Micro Focus support for access 
instructions.

This README file contains a basic introduction. More in-depth instructions for using the
IDOL Docker images can be found in the _IDOL Docker Technical Note_, available from the
[Micro Focus IDOL Documentation pages](https://www.microfocus.com/documentation/idol/).

There are two main compose setups contained in this package - a basic IDOL setup
(_basic-idol_) and an IDOL Data Admin setup (_data-admin_).

Each setup folder contains:
 *  An `.env` file defining variables referenced in the Compose files, which you will need to edit. 
    In particular you must set the LICENSESERVER_IP variable to the IP address of a valid
    IDOL License Server that will provide licensing for the system.
 *  A `docker-compose.yml` that defines the base IDOL system.
 *  Additional Compose files which may be used to extend the system by adding optional components
    or features. Add these features to the base system by using the `-f` flag to specify multiple
    Compose files to `docker-compose`:
    
        docker-compose -f docker-compose.yml -f docker-compose.<extension>.yml ...
        

## basic-idol

This defines a basic IDOL system with a single Content engine available for indexing. 
An IDOL NiFi ingestion system is used to extract and index document contents into Content. 
An IDOL Find UI is also available for queries.
IDOL Community provides login functionality for Find.

NiFi is also configured to run eduction processing on ingested documents. This
will identify any pieces of PII (Personally Identifiable Information) within
a document's main content field. Any such information is added to the document
as a separate field before it is indexed into Content.

To use this system, run the following commands in the _basic-idol_ directory:

    docker-compose up

Any documents that you copy into a particular directory within the system will
be detected and ingested by the NiFi setup. For example:

    docker cp example.pdf basic-idol_idol-nifi_1:/idol-ingest/

If you prefer to use a bind mount then you can edit the `docker-compose.bindmount.yml`
file and run:

    docker-compose -f docker-compose.yml -f docker-compose.bindmount.yml up

By default, only port 8080 is exposed and provides access to:
 -  `http://<dockerhost>:8080/nifi/` - the NiFi admin interface
 -  `http://<dockerhost>:8080/find/` - the Find user interface, with an admin/admin logon provided

If you want direct access to all of the container ports, then you can use the 
`docker-compose.expose-ports.yml` file.

### `docker-compose.add-docsec.yml`

This adds document security functionality to the basic system.
It uses an LDAP server to manage user and group details, plus
an OmniGroupServer to expose these. Whenever a user logs into Find, a security
string is generated for them: this will be used whenever they make a query.

If you want to use this system, you must edit `docker-compose.add-docsec.yml` to
reflect the settings for the LDAP server that you want to use. This includes
providing a password for a user who is able to search everywhere within that
server.

To use this system, run the following commands in the basic-idol directory:

    docker-compose -f docker-compose.yml -f docker-compose.add-docsec.yml up

You can log into Find using a user/password combination from the LDAP server you
configured. Note that all such users will have the basic Find role, so the
interface will look different compared to the admin user's login.

### `docker-compose.add-mmap.yml`

This adds IDOL Media Server and IDOL MMAP functionality to the basic system.

Media Server allows processing of files such as images, videos or audio
recordings. The NiFi setup will use Media Server functionality as part of its file
ingestion process.

MMAP is the Media Management and Analysis Platform, which allows for more advanced
usage of files processed by Media Server.

To use this system, run the following commands in the basic-idol directory:

    docker-compose -f docker-compose.yml -f docker-compose.add-mmap.yml up

This exposes:
 -  `http://<dockerhost>:8080/mmap/` - The MMAP interface


## data-admin

This creates containers for all the IDOL components required to run IDOL Data Admin.
This includes an IDOL Answer Server, with Answer Bank, Fact Bank and Passage Extractor
answer systems configured.

To use this system, run the following commands in the _data-admin_ directory:

    docker-compose up

By default, only port 8080 is exposed and provides access to the Data Admin UI.

If you want direct access to all of the container ports, then you can use the 
`docker-compose.expose-ports.yml` file.

## Use SSL/TLS Communications

Each docker compose set up directory contains a `idol-ssl.env` environment file and a 
`docker-compose.ssl.yml` Compose file, which can be used to configure the set up to use SSL/TLS.

You must provide either SSL certificates for the IDOL components (recommended), 
or an OpenSSL-based Certificate Authority to generate the certificates when you run the containers.
Before starting the containers, you must modify these files to ensure a bind mount containing the 
certificates, and environment variables relating to your issuing CA, are correctly configured. 
You must also set up trust stores for your user interfaces (Find, MMAP, and Data Admin), 
to allow them to securely communicate with the SSL-activated IDOL components.

Step-by-step instructions on how to make these changes can be found in the _IDOL Docker Technical Note_.

Once you have configured the environment, include the `docker-compose.ssl.yml` in the 
`docker-compose up` command. For example:

    docker-compose -f docker-compose.yml -f docker-compose.ssl.yml up
    
For the basic-idol setup, if you also want to include MMAP, you must also add the 
`docker-compose.add-mmap.ssl.yml` file to the `up` command.

If the containers cannot either find or generate an appropriate certificate for the component,
the `docker-compose up` command exits with an error.
