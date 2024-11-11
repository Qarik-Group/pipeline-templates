echo "Example commands for setting up credhub for your pipeline:"
echo
echo "For GitHub:"
echo "team=${team}"
echo "credhub set -n /concourse/\${team}/github-access-token -t value -v \"\$(echo \${GITHUB_TOKEN})\""
echo "credhub set -n /concourse/\${team}/github-private-key  -t value -v \"\$(cat ~/.ssh/id_rsa)\""
echo
echo "For Cloud Foundry ($(jq .Target -r ~/.cf/config.json)):"
echo "credhub set -n /concourse/\${team}/cf-username         -t value -v \"your-username\""
echo "credhub set -n /concourse/\${team}/cf-password         -t value -v \"your-password\""
