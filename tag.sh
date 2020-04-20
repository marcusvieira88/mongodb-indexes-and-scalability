#!/bin/bash

branch=$(git rev-parse --abbrev-ref HEAD)
latest=$(git tag  -l --merged master --sort='-*authordate' | head -n1)

echo ${latest}
major="0"
minor="0"
patch="0"
count="0" 
if [ -n "${latest}" ]
then
    echo 'Test Marcus'
    semver_parts=${latest//./}
    echo ${semver_parts}
    major=${semver_parts[0]}
    echo ${major}
    minor=${semver_parts[1]}
    echo ${minor}
    patch=${semver_parts[2]}
    echo ${patch}
    count=$(git rev-list HEAD ^${latest} --ancestry-path ${latest} --count)
    echo ${count}
fi

version=""

case $branch in
   "master")
      version=${major}.$((minor+1)).0
      ;;
   "feature/*")
      version=${major}.${minor}.${patch}-${branch}-${count}
      ;;
   *)
      >&2 echo "unsupported branch type"
      exit 1
      ;;
esac

echo ${version}
exit 0