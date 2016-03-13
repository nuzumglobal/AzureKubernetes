  - path: /etc/kubernetes/addons/skydns-svc.yaml
    owner: root
    permissions: '0640'
    content: |
      apiVersion: v1
      kind: Service
      metadata:
        name: kube-dns
        namespace: kube-system
        labels:
          k8s-app: kube-dns
          kubernetes.io/cluster-service: "true"
          kubernetes.io/name: "KubeDNS"
      spec:
        selector:
          k8s-app: kube-dns
        clusterIP: 10.16.0.3
        ports:
        - name: dns
          port: 53
          protocol: UDP
        - name: dns-tcp
          port: 53
          protocol: TCP
