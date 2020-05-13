# DevEnv

Ever wondered why it is so complicated to set up a local development environment with multiple hosts?

* A development environment, that uses TLS by default?
* With local domain names for your services?
* That supports docker?
* Which allows you to work on multiple projects at once without switching VMs or Containers?
* Which is working on Linux, MacOS and Windows?
* And just needs some minor customizations of your existing setup?

**You've come to the right place, this is DevEnv and it will simplify your and your developers life.**

No matter if you are a Frontend Developer, Java Developer, PHP Developer, Python, Ruby or NodeJS Developer. 
All Developers share the same pain: their code works locally, but won't work on staging and production environments 
in some cases, because their development environment differs too hard from staging/production. 


## Quickstart

To get it running, clone the repo and run the installer for your operating system.
When everything was set up successfully, you should be able to see the dashboard when
you open https://traefik.dev.env/ in your browser.
Firefox users on Windows please see the note below in the install section.


## Installation

#### Linux

Requirements: git, docker, docker-compose, systemd
```bash
git clone git@github.com:dev-rke/devenv.git
cd devenv/
./install-linux.sh
```

#### MacOS

Requirements: git, docker, docker-compose, brew
```bash
git clone git@github.com:dev-rke/devenv.git
cd devenv/
./install-macos.sh
```

#### Windows

Requirements: git, docker, docker-compose
Run in powershell with admin rights:
```powershell
git clone git@github.com:dev-rke/devenv.git
cd devenv/
.\install-windows.ps1
```

##### Important note for Firefox Users on Windows:
Firefox will not trust your certificate by default, because it does not load certificates from the windows certificate store.

To solve this you have two options:

**a) via [about:config](about:config)**
* accept the warning
* search for the key "security.enterprise_roots.enabled"
* change its value to "true" using a double click

**b) import the root certificate manually**
* go to the [Preferences](about:preferences)
* search for certificates section
* import the Root Certificate manually from %localappdata%/mkcert/


## Register your own Container

Technically you need a container providing a HTTP web server on port 80.
Please do not expose webserver ports (80, 443) to your host, as these are already used by DevEnv.
The container providing the webserver has to be within the ```devenv``` network and needs a ```Subdomains```-Label.

In this example we use nginx, a simple and lightweight webserver.
Create a new folder "nginx" and create a ```docker-compose.yml``` with the following contents:
```yaml
version: '2'
services:
  web:
    image: nginx:alpine
    label:
      - "Subdomains=my-server"
    networks:
      - devenv

networks:
  devenv:
    external: true
```

After running ```docker-compose up -d``` your new container is available via HTTP only: http://my-server.dev.env

To get it running only via HTTPS, you have to add the following label:
```yaml
- "traefik.http.routers.web-nginx-https.tls=true"
``` 

If you need both HTTP and HTTPS, please use these labels:
```yaml
- "traefik.http.routers.web-nginx-http.tls=false"
- "traefik.http.routers.web-nginx-https.tls=true"
``` 
To apply these settings, just do a ```docker-compose down -v``` to stop your container 
and ```docker-compose up -d``` to run it again.
A good non-conflicting naming schema for a router is ```<container name>-<project name>-<scheme>```.
All subdomains defined via ```Subdomains``` property apply to all rules. 

These labels follow the standard docker configuration settings of the 
reverse proxy [traefik](https://containo.us/traefik/).

#### Multiple subdomains for a single container

If your container needs multiple subdomains, there are two approaches.
The first and simple approach is to expand the ```Subdomains``` label with comma separated subdomains:
```yaml
- "Subdomains=nginx,webserver,myproject"
```
This will make your container available under these domains:
* http://nginx.dev.env
* http://webserver.dev.env
* http://myproject.dev.env

Whitespaces before or after the comma will break the behaviour!

The second approach is based on regular traefik configuration, just register your domains as regular rules via label:
```yaml
 - "traefik.http.routers.nginx-http.rule=Host(`nginx.dev.env`, `webserver.dev.env`, `myproject.dev.env`)"
```
or in a more complex scenario, which allows to define more settings per rule:
```yaml
 - "traefik.http.routers.nginx-http.rule=Host(`nginx.dev.env`)"
 - "traefik.http.routers.webserver-http.rule=Host(`webserver.dev.env`)"
 - "traefik.http.routers.myproject-http.rule=Host(`myproject.dev.env`)"
```

## Deliver static files

Especially Frontend Developers need support by a local webserver with TLS, 
due to the fact that there are typically things like CORS, 
or technical restrictions for some APIs when there is no TLS.

To set up your project, go to the path provided in the file ```devenv/.env```.
Within this path, just create the folder structure and a file ```test/web/index.html```
and insert the content ```<h1>Hello World</h1>```. Afterwards open https://test.dev.env in your browser.

All folders will be resolved dynamically, so by creating another folder you can set up another subdomain. 
This functionality is especially for some instant projects, prototyping, testing and so on, 
without the need of a heavy virtual machine or containers.


## How does it work?

The project is a collage of multiple projects:
* [traefik](https://containo.us/traefik/)
* [nginx](https://www.nginx.com/)
* [mkcert](https://github.com/FiloSottile/mkcert)
* [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html)

#### Setup
The setup process downloads mkcert, generates and registers a CA and generates local certificates for *.dev.env. 
Then a local resolver is registered in your operating system to resolve any request via dnsmasq. 
Afterwards a global docker network will be set up to communicate between the containers. 
At the end docker-compose is booting up DevEnv to serve.

#### Request processing
Before a request gets processed, your browser, curl or whatever will resolve it's domain name.
This will be done using the local domain resolver of your operating system, which will itself lookup 
only ```*.dev.env``` domains. All ```*.dev.env``` domains are enforced to be resolved via dnsmasq running 
on your loop back device 127.0.0.1, which itself will resolve any subdomain of ```*.dev.env``` to the loop back
device as well. Therefore a browser will do it's HTTP request to ```127.0.0.1:80``` and HTTPS to ```127.0.0.1:443```.

The processing of the final request travels through traefik. If there exists a route with a container (by defining the
```Subdomains``` label or other standard traefik labels) it will use this route to finish the request.
If no route is specified, the request falls back to the static nginx service of DevEnv, 
which will deliver static files from your configured web folder, see .env file for the configured path. 
The web folder on your host is different on all operating systems.

## The *.dev.env domain

Since google fucked up the ```*.dev``` top level domain (TLD), a lot of people switched to ```*.localhost```, 
```*.test``` or some crazy TLDs like ```*.invalid``` and ```*.example```. 
These TLDs are listed by the [RFC 2606](https://tools.ietf.org/html/rfc2606#page-2) for local testing purposes. 

In my opinion, these TLDs are useless. They are very long, which causes typing errors and are hard to remember.
Also the TLD ```*.localhost``` is typically assigned to the loop back IP address.
Furthermore, developers and companies have sometimes services running on these testing TLDs, 
which might conflict when i provide another service locally.
Therefore i chose ```*.dev.env```.
Currently (May 2020) ```*.env``` is not a registered top level domain and i assume this will be the case for the next years.
The chosen domain ```dev.env``` limits the amount of overridden domains to a minimum,
even when the TLD gets officially registered you can still use the ```*.env``` TLD, except for ```dev.env```.

Furthermore it is not possible to generate certificates for a whole TLD like ```*.env```, 
so i chose the approach using a concrete subdomain via ```*.dev.env```.
For People who would like to use sub-subdomains: you have to generate a new multi domain wildcard certificate yourself, 
it is not possible to use double wildcards like ```*.*.dev.env```.