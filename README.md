# DevEnv

Ever wondered why it is so complicated to set up a local development environment with multiple hosts?
A development environment, that uses TLS by default?
With local domain names for your services?
That supports docker?
Which allows you to work on multiple projects at once without switching VMs or Containers?
Which is working on Linux, MacOS and Windows?
And just needs some minor customizations of your existing setup?

**You've come to the right place, this is devenv and it will simplify your and your developers life.**

No matter if you are a Frontend Developer, Java Developer, PHP Developer, Python, Ruby or NodeJS Developer. 
All Developers share the same pain: their code works locally, but won't work on staging and production environments 
in some cases, because their development environment differs too hard from staging/production. 


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

In this example we use nginx, a simple and lightweight webserver.
Create a new folder "nginx" and create a ```docker-compose.yml``` with the following contents:
```yaml
version: '2'
services:
  nginx:
    image: nginx:alpine
    label:
      - "Subdomain=my-server"
    networks:
      - devenv

networks:
  devenv:
    external: true
```

After running ```docker-compose up -d``` your new container is available:
* via HTTP: http://my-server.dev.env 
* via HTTPS: https://my-server.dev.env

Please do not bind webserver ports (80, 443) to your host, as these are already in use by devenv.

The container providing the webserver has to be within the ```devenv``` network and needs a ```Subdomain```-Label.

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
* traefik
* nginx
* mkcert
* dnsmasq

The setup process downloads mkcert, generates and registers a CA and generates local certificates for *.dev.env. 
Then a local resolver is registered in your operating system to resolve any request via dnsmasq from *.dev.env to localhost. 
Afterwards a global docker network will be set up to communicate between the containers. 
At the end docker-compose is booting up.

The processing of a request travels through nginx for ssl termination and which also decides if a request should 
be routed to the local file system, when a matching folder exists. 
If there is no matching folder the request will be rerouted to traefik, 
which itself tries to resolve the subdomain to a container.

## The *.dev.env domain

Since google fucked up the ```*.dev``` top level domain (TLD), a lot of people switched to ```*.localhost```, 
```*.test``` or some crazy TLDs like ```*.invalid``` and ```*.example```. 
These TLDs are listed by the [RFC 2606](https://tools.ietf.org/html/rfc2606#page-2) for local testing purposes. 

In my opinion, these domains are useless. They are very long, which causes typing errors and are hard to remember.
The TLD ```*.localhost``` is typically assigned to the loop back IP address.
Furthermore, developers and companies have already services running on these testing TLDs, 
which might conflict when i provide another service.
Therefore i chose ```*.dev.env```.
Currently (May 2020) ```*.env``` is not a registered top level domain and i assume this will be the case for the next years.
The chosen domain ```dev.env``` limits the amount of overridden domains to a minimum,
even when the TLD gets officially registered you can still use the ```*.env``` TLD, except for ```dev.env```.

Furthermore it is not possible to generate certificates for a whole TLD like ```*.env```, 
so i chose the approach using a concrete subdomain via ```*.dev.env```.
For People who would like to use sub-subdomains: you have to generate a new multi domain wildcard certificate yourself, 
it is not possible to use double wildcards like ```*.*.dev.env```.