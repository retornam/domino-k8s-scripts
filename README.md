# domino-k8s-scripts - shell scripts for generating,installing and destroying domino.


~~~
├── README.md
├── destroy.sh
├── domino
├── generate.sh
├── install.sh
└── service.sh
~~~

* `generate.sh` - generates a new domino.yml file in the folder domino. The
  generated file is in the format domino-VERSION-CURRENTDATE-UNIXTIME.yml

* `install.sh` - installs ./domino/domino.yml using a configmap and
                 the fleetcommand-agent container in the default cluster namespace.

* `service.sh` - installs ./domino/domino.yml and a specific service using a configmap and
                 the fleetcommand-agent container in the default cluster namespace.

* `destroy.sh` - destroys the domino cluster.
