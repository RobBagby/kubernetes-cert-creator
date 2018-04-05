#!/bin/sh
/usr/bin/openssl genrsa -out /certs/${USER_NAME}.pem 2048 && \
/usr/bin/openssl req -new -key /certs/${USER_NAME}.pem -out /certs/${USER_NAME}.csr -subj "/CN=users:${USER_NAME}${USER_GROUPS}"
encoded_string=$(cat /certs/${USER_NAME}.csr | base64 | tr -d '\n')

echo 'apiVersion: certificates.k8s.io/v1beta1\nkind: CertificateSigningRequest\nmetadata:\n  name: user-request-'${USER_NAME}'\nspec:\n  groups:\n  - system:authenticated\n  request: '$encoded_string'\n  usages:\n  - digital signature\n  - key encipherment\n  - client auth' > /certs/cert-request-${USER_NAME}.yaml

echo "Creating Cert Request in Cluster"
kubectl create -f /certs/cert-request-${USER_NAME}.yaml

echo "Approving the Cert Request"
kubectl certificate approve user-request-${USER_NAME}

kubectl get csr user-request-${USER_NAME} -o jsonpath='{.status.certificate}' | base64 --decode > /certs/${USER_NAME}.crt
echo "Fetching Certificate:"
cat /certs/${USER_NAME}.crt
echo

echo Creating /certs/config-${USER_NAME}
touch /certs/config-${USER_NAME}
echo

echo Setting cluster in /certs/config-${USER_NAME}
kubectl config set-cluster ${CLUSTER_NAME} --kubeconfig /certs/config-${USER_NAME} --server ${SERVER_URL} --certificate-authority='/usr/src/certs/ca.crt' --embed-certs=true
echo

echo Setting credentials for user ${USER_NAME} in /certs/config-${USER_NAME}
kubectl --kubeconfig /certs/config-${USER_NAME} config set-credentials ${USER_NAME} --client-certificate=/certs/${USER_NAME}.crt --client-key=/certs/${USER_NAME}.pem --embed-certs=true
echo

echo Setting the context ${CLUSTER_NAME}-${USER_NAME} for user ${USER_NAME} and cluster ${CLUSTER_NAME} in /certs/config-${USER_NAME}
kubectl --kubeconfig /certs/config-${USER_NAME} config set-context ${CLUSTER_NAME}-${USER_NAME} --cluster=${CLUSTER_NAME} --user=${USER_NAME}
echo

echo Using Context ${CLUSTER_NAME}-${USER_NAME}
kubectl --kubeconfig /certs/config-${USER_NAME} config use-context ${CLUSTER_NAME}-${USER_NAME}
echo

echo kubeconfig file /certs/config-${USER_NAME} created
echo
