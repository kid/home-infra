bundle: {
	apiVersion: "v1alpha1"
	name:       "flux-aio"
	instances: {
		"flux": {
			module: {
				url:     "oci://ghcr.io/stefanprodan/modules/flux-aio"
				version: "latest"
			}
			namespace: "flux-system"
			values: {
				hostNetwork:     true
				securityProfile: "privileged"
				controllers: notification: enabled: true
				tmpfs: enabled: true
				env: {
					KUBERNETES_SERVICE_HOST: "localhost"
					KUBERNETES_SERVICE_PORT: "7445"
				}
			}
		}
	}
}
