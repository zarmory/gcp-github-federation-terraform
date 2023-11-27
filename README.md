Quickly bootstrap your project with terraform'ed GCP-GitHub federation.

# Why?
In the past, to gain access to our GCP env inside GitHub actions, we used GitHub secrets to store GCP service account keys.
It worked but for me it always felt like walking a thin line. Thankfully now GitHub support OICD tokens and we can 
[setup](https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions)
GCP Workload Identity Federation to grant key-less access for our GitHub actions to our GCP environment.

There are plenty of guides out there on how to do it but it takes some effort to follow them, particularly if you want to terraform everthing - it
adds the extra work of bootstrapping terraform configuration itself (using local state to create remote state storage, upload state, switch
to impersonalization, etc.). Hence, after repeating this a couple of times I decided to have repository template to save time to me and hopefully you as well.

# What do you get?
After cloning and configuring this repo, with a couple of commands, you'll get the following:
* Terraform state bucket created
* Terraform service account created and permissions assigned
* GitHub OIDC federation set up
* Sample GitHub Actions workflows to validate and apply your configuration

All in all just ~100 lines of terraform code, including comments. Basically, just clone, configure and start building.

# Usage

Clone/download the repo. Make sure you have:
* Your Google Cloud SDK available and authenticated
* Your target GCP project created and its ID exposed in `CLOUDSDK_CORE_PROJECT` env var
* `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` env var set to `terraform@${CLOUDSDK_CORE_PROJECT}.iam.gserviceaccount.com`
* GNU Make and `envsubst` available

Or, if you use Nix and direnv, simply copy `envrc.sample` to `.envrc`, set `CLOUDSDK_CORE_PROJECT`, get your shell activated and you are done!

## Update config - ❗ DO NOT SKIP THIS STEP ❗
* Edit `variables.tf` and set defaults for:
  * `github_repository` - the name of your repository, in the `<org/user>/<repo name>` format.
  * `project_admins` - list of admins for your GCP project, in the IAM membership format.
    At the very least, it should contain your current user, e.g. `user:<your email>`
* Run `make gh-bootstrap`. It will patch `.github/actions/setup-env/action.yaml` with proper project ID and service account
* Edit `.github/actions/setup-env/action.yaml` and **remove** `Set environment variables for terraform` **step** (yes, the whole step) - t
  It's there as a safe guard that stops CI if it runs in a cloned repo. I **do not** want to set repo/admin defaults in `variables.tf`
  to reduce the chances that you make *me* admin on *your* project, hence I inject those vars in the GH action but with a safeguard.

## Let's apply it
* `make tf-bootstrap` - This will authenticate as your *current user*, and will create terrafrom service account and the state bucket. TF state is stored locally
* All going well, run `make tf-init` then followed by `make tf-apply`. From this stage on, terrafrom run under Terrafrom service account (through impersonation)

You are done! Happy building!

# Dev env
I heavily use direnv and Nix to make developement environment setup easy. Included GitHub Actions use Nix as well to create the same environment every time.

Nix has a steep learning curve but it will change the way you manage software forever. Environment dependencies are listed in `.nix/dependencies.nix` and
the exact versions of dependencies will be availbe inside GitHub Actions envrionement, pinned to the specified commit in the nixpkgs repo.

If you [install Nix](https://nixos.org/download) (the package manager) and enable `direnv` through [Home Manager](https://github.com/nix-community/home-manager)
then you can have your dev environment activated to have the same dependencies that CI would have, severely reducing cases where it works on your machine
but breaks in CI.

# CI
There are workflows supplied that check PR for terraform style, and apply your terraform configration on push to the `main` branch. The best part is the
`.github/actions/setup-env/action.yaml` GH action that setups OIDC federation, Nix, and Terraform, so that you don't need to repeat the same steps in
every action.
