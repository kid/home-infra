bundle: {
	_cluster_name: string @timoni(runtime:string:CLUSTER_NAME)
	_gh_org:       string @timoni(runtime:string:GITHUB_ORG)
	_gh_repo:      string @timoni(runtime:string:GITHUB_REPO)

	apiVersion: "v1alpha1"
	name:       "flux-aio"
	instances: {
		"flux-system": {
			module: {
				url:     "oci://ghcr.io/stefanprodan/modules/flux-git-sync"
				version: "latest"
			}
			namespace: "flux-system"
			values: {
				git: {
					url:  "https://github.com/\(_gh_org)/\(_gh_repo).git"
					path: "clusters/\(_cluster_name)"
					ref:  "refs/heads/main"
					// flux itself is managed by terraform
					ignore: "clusters/**/flux-system/"
				}
				sync: wait: true
			}
		}
	}
}
