#!/bin/bash
version=$1
text="DApi framework for iOS"

if [ -z "$version" ]
then
      echo "version can't be empty. (sh publish.sh 1.0)"
      exit 1;
fi

branch=$(git rev-parse --abbrev-ref HEAD)
repo_full_name=$(git config --get remote.origin.url | sed 's/.*:\/\/github.com\///;s/.git$//')
token=$(git config --global github.token)

generate_post_data()
{
  cat <<EOF
{
  "tag_name": "$version",
  "target_commitish": "$branch",
  "name": "$version",
  "body": "$text",
  "draft": false,
  "prerelease": false
}
EOF
}

rm -f DApi-ios.zip
zip -r DApi-ios.zip LICENSE DApi.framework
git add DApi-ios.zip
git commit -m "upload zip"
git push

echo "Create release $version for repo: $repo_full_name branch: $branch"
curl --data "$(generate_post_data)" "https://api.github.com/repos/$repo_full_name/releases?access_token=$token"

sed "s/{version}/$version/g" podspec.src > DApi-ios.podspec

pod trunk push DApi-ios.podspec --allow-warnings

rm -f DApi-ios.podspec
