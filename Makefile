ifndef CLOUDSDK_CORE_PROJECT
  $(error Please define CLOUDSDK_CORE_PROJECT env var before operating this Makefile)
endif

$(info GCP Project is set to: $(CLOUDSDK_CORE_PROJECT))
$(info ) # Newline

.PHONY: gh-bootstrap
gh-bootstrap: PROJECT_NUMBER = $(shell gcloud projects describe $(CLOUDSDK_CORE_PROJECT) --format='value(projectNumber)')
gh-bootstrap: WIP = projects/$(PROJECT_NUMBER)/locations/global/workloadIdentityPools/github/providers/gh-actions
gh-bootstrap:
	sed -r \
		-e 's|([[:space:]]*service_account:).*|\1 terraform@$(CLOUDSDK_CORE_PROJECT).iam.gserviceaccount.com|' \
		-e 's|([[:space:]]*workload_identity_provider:).*|\1 $(WIP)|' \
		-i .github/actions/setup-env/action.yaml

.PHONY: tf-bootstrap
# Run this only when working with BARE project to boostrap TF
tf-bootstrap: GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=
tf-bootstrap: 
	rm -rf backend.tf
	terraform init
	terraform apply \
	  --target=module.project_services \
	  --target=google_storage_bucket.state \
	  --target=google_service_account.terraform \
	  --target=google_project_iam_member.terraform \
	  --target=google_service_account_iam_binding.terraform_token_creator \
		--input=false \
		--var=gcp_project_id=$(CLOUDSDK_CORE_PROJECT) \
	  --auto-approve 
	@echo -e "\n\n\n\nAll done!\n=========\n"
	@echo -e '>>> Now run "make tf-init" and make sure to say "yes" to import the local state into GCS'
	@echo -e '>>> Then follow with "make tf-apply" to finish bootstrap and verify that impersonation is working'
	@echo -e '!!! You may need to wait a minute for IAM changes to propagate\n\n'

.PHONY: tf-validate-style
tf-validate-style:
	@echo -n "Checking whether TF files are properly formatted... "
	@if ! terraform fmt --check --diff --recursive; then \
		echo -e "\n\n======================================================================"; \
		echo        "!!! Please format your TF files with \`terraform fmt' before committing"; \
		echo        "======================================================================"; \
		exit 1; \
	else \
		echo "All good"; \
	fi

.PHONY: tf-validate
tf-validate: backend.tf
	terraform validate

.PHONY: tf-init
tf-init: backend.tf
	terraform init 

.PHONY: tf-show
tf-show: backend.tf
	terraform show 

.PHONY: tf-plan
tf-plan: backend.tf
	terraform plan \
		--input=false \
		--var=gcp_project_id=$(CLOUDSDK_CORE_PROJECT)

.PHONY: tf-apply
tf-apply: backend.tf
	terraform apply \
		--input=false \
		--var=gcp_project_id=$(CLOUDSDK_CORE_PROJECT)
		--auto-approve \

.PHONY: tf-destroy
tf-destroy: backend.tf
	terraform destroy \
		--input=false \
		--var=gcp_project_id=$(CLOUDSDK_CORE_PROJECT) \
		--auto-approve

# Has to be PHONY, otherwise project change (env var) doesn't trigger recreation
.PHONY:backend.tf
backend.tf: backend.tf.tmpl
	cat $< | envsubst >$@
