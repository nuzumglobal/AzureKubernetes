  - path: /etc/kubernetes/addons/skydns-rc.yaml
    owner: root
    permissions: '0640'
    content: |
      apiVersion: v1
      kind: ReplicationController
      metadata:
        name: kube-dns-v9
        namespace: kube-system
        labels:
          k8s-app: kube-dns
          version: v9
          kubernetes.io/cluster-service: "true"
      spec:
        replicas: 3
        selector:
          k8s-app: kube-dns
          version: v9
        template:
          metadata:
            labels:
              k8s-app: kube-dns
              version: v9
              kubernetes.io/cluster-service: "true"
          spec:
            containers:
            - name: etcd
              image: gcr.io/google_containers/etcd:2.0.9
              resources:
                limits:
                  cpu: 100m
                  memory: 50Mi
              command:
              - /usr/local/bin/etcd
              - -data-dir
              - /var/etcd/data
              - -listen-client-urls
              - http://127.0.0.1:2379,http://127.0.0.1:4001
              - -advertise-client-urls
              - http://127.0.0.1:2379,http://127.0.0.1:4001
              - -initial-cluster-token
              - skydns-etcd
              volumeMounts:
              - name: etcd-storage
                mountPath: /var/etcd/data
            - name: kube2sky
              image: gcr.io/google_containers/kube2sky:1.11
              resources:
                limits:
                  cpu: 100m
                  memory: 50Mi
              args:
              # command = "/kube2sky"
              - -domain=kube.local
              - -kube_master_url=http://${ConditionHost}:8080
            - name: skydns
              image: gcr.io/google_containers/skydns:2015-03-11-001
              resources:
                limits:
                  cpu: 100m
                  memory: 50Mi
              args:
              # command = "/skydns"
              - -machines=http://localhost:4001
              - -addr=0.0.0.0:53
              - -domain=kube.local
              ports:
              - containerPort: 53
                name: dns
                protocol: UDP
              - containerPort: 53
                name: dns-tcp
                protocol: TCP
              livenessProbe:
                httpGet:
                  path: /healthz
                  port: 8080
                  scheme: HTTP
                initialDelaySeconds: 30
                timeoutSeconds: 5
              readinessProbe:
                httpGet:
                  path: /healthz
                  port: 8080
                  scheme: HTTP
                initialDelaySeconds: 1
                timeoutSeconds: 5
            - name: healthz
              image: gcr.io/google_containers/exechealthz:1.0
              resources:
                limits:
                  cpu: 10m
                  memory: 20Mi
              args:
              - -cmd=nslookup kubernetes.default.svc.kube.local localhost >/dev/null
              - -port=8080
              ports:
              - containerPort: 8080
                protocol: TCP
            volumes:
            - name: etcd-storage
              emptyDir: {}
            dnsPolicy: Default  # Don't use cluster DNS.
