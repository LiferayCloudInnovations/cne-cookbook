# How to Test

- Run `make saas-bad-configmap`
- Execute Sample object entry update and verify that the springboot service sees the update
- Run `kubectl apply -f` for both aaabad-configmap.yaml and bad-configmap.yaml
- Restart portal `kubectl rollout restart statefulset liferay-default`
- Verify that modifying sample object entry will again 
