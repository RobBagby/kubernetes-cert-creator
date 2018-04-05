# Kubernetes Cert Creator
The Kubernetes Cert Creator creates a certificate for a new user, using openssl to create a csr and the Kubernetes CA in your cluster to approve the signing request.  The Cert Creator then creates a kubernetes config file that can be used by the user to authenticate to the cluster.  

In order to do this, the Cert Creator requires that you pass the ca.crt from your kubernetes master to the docker container via a mapped volume, as well as a kubernetes config file that the container can use to authenticate to the cluster when creating the signing request and requesting approval.  That is also mapped via a volume.

# Specifics
This container performs the following:
* Uses openssl to create a pem and csr (certificate signing request)
* Creates a Kubernetes certificate signing request yaml file
* Calls kubectl create -f on the certificate signing request yaml file
* Calls kubectl certificate approve on the signing request
* Calls kubectl get on the resulting csr, parsing out the certificate
* Creates a new kubernetes configuration file
  * Sets the context, using the ca.crt provided via a volume map
  * Sets the credentials with the newly created credentials
  * Sets the current context to the new user and use-context on the new context 

# Docker Image
The Docker image is built on top of the Ubuntu 17.10 base image. It is available on DockerHub as:

[rbagby/kubernetes-cert-creator](https://hub.docker.com/r/rbagby/kubernetes-cert-creator/)

# Run
## Windows
(guidance coming soon)

## Linux or Mac
```
$ docker run --rm \
	-v /local_path_to_ca.crt:/usr/src/certs/ca.crt \
	-v /local_path_where_you_want_config_file_created:/certs \
	-v ~/.kube/config:/root/.kube/config \
	-e USER_NAME=username_to_create \
	-e GROUPS=/o=group_to_assign_user_to \
	-e CLUSTER_NAME=clustername \
	-e SERVER_URL=URL_to_server \
	rbagby/kubernetes-cert-creator:0.1
```

The following is a working example on my mac:
```
$ docker run --rm \
	-v /Users/robbagby/Documents/Development/Temp/input/ca.crt:/usr/src/certs/ca.crt \
	-v /Users/robbagby/Documents/Development/Temp/output:/certs \
	-v ~/.kube/config:/root/.kube/config \
	-e USER_NAME=test \
	-e GROUPS=/o=deployers \
	-e CLUSTER_NAME=clustername \
	-e SERVER_URL=https://bagbydefntwk.westus.cloudapp.azure.com \
	rbagby/kubernetes-cert-creator:0.1
```

I could then use the generated config file to connect to my cluster
```
$ export KUBECONFIG=/Users/robbagby/Documents/Development/Temp/output/config-test
$ kubectl get pods

Error from server (Forbidden): pods is forbidden: User "users:test" cannot list pods in the namespace "default"
```

Clearly the user does not have any rights, but you were able to connect.  Update RBAC permissions to give the user the rights they require.

## Details on parameters
You need to provide several things in order to create a kubernetes config file for a new user:

| Asset | Type | Description |
| --------------------- | ---------------------- | --------------------------------------- |
| ca.crt | Mapped Volume |Map the local path to the ca.crt from your cluster to /usr/src/certs/ca.crt.  The ca.crt file can be found at /etc/kubernetes/certs/ca.crt on your master if you used acs-engine to create the cluster. You can use scp (or pscp on Windows) to copy this file from your server |
| kubeconfig file | Mapped Volume | Map the path to a kubeconfig file to the file /root/.kube/config.  Make sure you map the actual kubeconfig file to the actual file named config in the container |
| Output directory | Mapped Volume | Map the path of a directory where you want the config file created to /certs in the container |
| USER_NAME | Environment Variable | The name of the user to create |
| GROUPS | Environment Variable | The groups to add the user to in the format: /o=groupname |
| CLUSTER_NAME | Environment Variable | The name of the cluster to be used only as the clustername in the kubeconfig file |
| SERVER_URL | Environment Variable | The URL to the master in your cluster |
