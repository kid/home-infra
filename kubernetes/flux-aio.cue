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
				controllers: notification: enabled: false
				// env: {
				// 	"KUBERNETES_SERVICE_HOST": "localhost"
				// 	"KUBERNETES_SERVICE_PORT": "7445"
				// }
			}
		}
		"cluster-addons": {
			module: url: "oci://ghcr.io/stefanprodan/modules/flux-git-sync"
			namespace: "flux-system"
			values: git: {
				url:  "https://github.com/kid/home-infra"
				ref:  "refs/heads/feat/talos"
				path: "./kubernetes/cluster-addons"
			}
		}
		// "apps": {
		// 	module: url: "oci://ghcr.io/stefanprodan/modules/flux-git-sync"
		// 	namespace: "flux-system"
		// 	values: git: {
		// 		url:  "https://github.com/kid/home-infra"
		// 		ref:  "refs/heads/feat/talos"
		// 		path: "./kubernetes/apps"
		// 	}
		// }
	}
}
