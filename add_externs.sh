#!/bin/bash

pushd public
svn propset svn:externals "paraffin https://github.com/quidquid/paraffin/trunk" . 
svn up
svn commit -m "added paraffin extern"
popd

mkdir vendor/gems
svn add vendor/gems
svn commit vendor/gems -m "created vendor/gems"
pushd vendor/gems
svn propset svn:externals "bedrock http://svn.quidquid.net/bedrock/v2" .
svn up
svn commit -m "added bedrock extern"
popd
