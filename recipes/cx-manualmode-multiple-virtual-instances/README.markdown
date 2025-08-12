# How to reproduce

## Steps

1. go to root of this git repo
1. `make cx-direct-deploy-test`
1. assert that CETConfiguration is there
   1. login to gogo shell
   1. `addcommand cm (service (servicereference "org.osgi.service.cm.ConfigurationAdmin"))`
   1. `listconfigurations null | grep CETConfiguration` and make sure one entry
      is found
   1. Add custom element 1 on the front page of portal
1. `export RECIPE=cx-direct-deploy-test` `make undeploy-dxp`
1. `kubectl delete pvc liferay-persistent-volume-liferay-default-0 -n liferay-system`
   This will delete the osgi/state which has a cache of the
   liferaycustomelement1 bundle
1. uncomment line in gradle.properties for dir.exclude.globs
1. `make deploy-dxp` now the liferay-custom-element-1.zip will no longer be in
   the osgi/client-extensions folder
1. Look at the Client Extensions UI and notice the Liferay Sample Custom Element
   1 is still visible
1. load the homepage and notice the 404 errors
1. Query the database from the postgresql pod
   `select * from configuration_ where configurationid='com.liferay.client.extension.type.configuration.CETConfiguration~liferay-sample-custom-element-1'`
1. Delete this row in the configuration\_
1. undeploy and redeploy dxp `make undeploy-dxp deploy-dxp`
1. verify that the Client Extension doesn't show up in the UI
