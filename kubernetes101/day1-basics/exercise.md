# Kubernetes 101 — Day 1 Hands-on Exercises

**Class:** July DevOps Bootcamp  
**Topic:** Kubernetes fundamentals with Kind and kubectl  
**Repository materials:** [kubernetes101/day1-basics](https://github.com/akhileshmishrabiz/july-devops/tree/main/kubernetes101/day1-basics)

## Goal

By the end of this lab, you should be able to create and inspect a local Kubernetes cluster, work with namespaces and Pods, investigate application behaviour using events and logs, and deploy an application using a Deployment and Service.

## Prerequisites

- Docker is installed and running.
- `kubectl` and [Kind](https://kind.sigs.k8s.io/) are installed.
- Terminal access to run commands.
- Clone the class repository:

```bash
git clone https://github.com/akhileshmishrabiz/july-devops.git
cd july-devops/kubernetes101/day1-basics
```

> If you already have a Kind cluster with a different name or configuration, check it before creating another one.

---

## Exercise 1 — Create and inspect a Kind cluster

Use the provided `kind-config.yaml`.

1. Read the YAML and identify how many nodes it defines and what roles they have.
2. Create a Kind cluster using this configuration. Give the cluster a meaningful name.
3. List the Kind clusters on your machine.
4. Use kubectl to list the cluster nodes.
5. Display additional details for each node, including its internal IP and container runtime.
6. Compare the Kubernetes nodes with the Docker containers running on your machine.

**Success criteria**

- The cluster is created successfully.
- You can see one control-plane node and three worker nodes.
- You can explain why Kind nodes also appear as Docker containers.

**Evidence to save:** Output of the node listing and the cluster listing.

---

## Exercise 2 — Explore namespaces

1. List all namespaces in the cluster.
2. List Pods in the `default` namespace.
3. List Pods in the `kube-system` namespace.
4. List Pods across all namespaces.
5. Create a namespace called `dev`.
6. Verify that the namespace exists.
7. In your own words, explain why Kubernetes uses namespaces.

**Think about it:** Does creating a namespace create a separate worker node or a separate Kubernetes cluster?

---

## Exercise 3 — Run and inspect a standalone Pod

Use the provided `pod-1-container.yaml`.

1. Read the manifest and identify its API version, resource kind, Pod name, container name, image, and declared container port.
2. Create the Pod using the YAML file.
3. List Pods and wait until the new Pod is running.
4. Inspect the Pod's details.
5. Find the node on which the Pod was scheduled and its Pod IP.
6. View the Pod's logs.
7. Open a shell inside the container, inspect the filesystem, and exit the shell.
8. Delete the Pod and verify that it is gone.

**Questions**

- What information did the Pod description show that the basic Pod listing did not?
- After you delete this standalone Pod, does Kubernetes create another one automatically? Explain what you observed.

**Success criteria:** You can create, inspect, access, and delete a Pod using kubectl.

---

## Exercise 4 — Investigate Pod events

1. Create the standalone Pod again.
2. Describe the Pod and review its events.
3. Identify events related to scheduling, image handling, and container startup.
4. View the container logs.
5. Delete the Pod when you are finished.

**Troubleshooting challenge:** Change the image in a *separate copy* of the manifest to a deliberately invalid image tag. Apply it and inspect the Pod's status, description, and events. Identify the symptom and the likely cause. Restore the valid image and clean up the test Pod.

Do not modify the original file unless you intend to restore it.

---

## Exercise 5 — Work with a multi-container Pod

Use `pod-multicontainer.yaml`.

1. Read the manifest and list each container name and image.
2. Apply the manifest.
3. Wait for the Pod to become ready, then inspect its status.
4. Use kubectl to view logs from each container individually.
5. Open a shell in the BusyBox container and run a few basic Linux commands.
6. Inspect the Pod's IP and explain whether the containers in the same Pod share the Pod network.
7. Delete the multi-container Pod and verify it has been removed.

**Questions**

- How many containers are defined in the Pod?
- How do you select a particular container when using `kubectl exec` or `kubectl logs`?
- Are multiple containers in one Pod the same thing as multiple Pods?

**Success criteria:** You can target a specific container inside a multi-container Pod.

---

## Exercise 6 — Deploy an application with a Deployment

Use `deployment.yaml`.

1. Read the manifest and identify the desired replica count, Pod template, labels, selector, image, and container port.
2. Apply the manifest.
3. Verify the Deployment and its ReplicaSet.
4. List the Pods created by the Deployment.
5. Confirm how many replicas are running.
6. Scale the Deployment down to two replicas.
7. Verify the new replica count.
8. Scale it back up to four replicas.
9. Delete one Pod managed by the Deployment and watch what happens.
10. Explain how this differs from running a standalone Pod.

**Questions**

- What is the relationship between a Deployment, a ReplicaSet, and Pods?
- Why does a replacement Pod appear after you delete one of the Deployment's Pods?
- Which field in the manifest helps the Deployment identify the Pods it manages?

**Success criteria:** You can scale a Deployment and observe its self-healing behaviour.

---

## Exercise 7 — Expose the Deployment using a Service

Use `service.yaml`.

1. Read the manifest and identify the Service selector, Service port, and target port.
2. Apply the Service manifest.
3. Inspect the Service and its endpoints or EndpointSlices.
4. Check that the Service selector matches the labels on the Deployment's Pods.
5. Use `kubectl port-forward` to forward a local port to the Service.
6. Open `http://localhost:8080` in a browser, or use curl, while port-forwarding is running.
7. Stop port-forwarding after you verify the page.
8. Scale the Deployment and check whether the Service still routes traffic to its Pods.

**Questions**

- Why can a Service continue to provide a stable endpoint even when individual Pods are replaced?
- What would happen if the Service selector did not match the Pod labels?
- What is the difference between a Service port and a target port?

**Success criteria:** You can reach the NGINX application through a Kubernetes Service using port-forwarding.

---

## Exercise 8 — Troubleshooting challenge

Complete these tasks without deleting and recreating the entire cluster.

1. Find a Pod that is not starting correctly and inspect its events.
2. Find the logs for a specific container in a multi-container Pod.
3. Identify which namespace contains a given Pod.
4. Find the worker node on which a Pod is running.
5. Diagnose a Service that has no matching endpoints by comparing its selector with the Pod labels.
6. Explain the difference between deleting a standalone Pod and deleting a Pod managed by a Deployment.

For each task, write down the command you used, the useful output you found, and your diagnosis.

---

## Exercise 9 — Clean up

Remove the resources created during this lab.

1. Delete the standalone and multi-container Pods if they still exist.
2. Delete the Service and Deployment created in the exercises.
3. Verify that the resources have been removed.
4. Delete the `dev` namespace after confirming it contains no work you need.
5. Delete the Kind cluster you created for this lab, if you no longer need it.

Be careful to delete only the cluster and resources created for this exercise.

---

## Submission checklist

Before you finish, make sure you can:

- [ ] Create a multi-node Kind cluster from a YAML configuration.
- [ ] List nodes, namespaces, and Pods.
- [ ] Create and delete a standalone Pod.
- [ ] Inspect Pod details, events, and logs.
- [ ] Execute commands in a selected container.
- [ ] Explain the basic purpose of namespaces.
- [ ] Deploy and scale an application using a Deployment.
- [ ] Explain how a Deployment replaces a deleted Pod.
- [ ] Expose an application using a Service and port-forwarding.
- [ ] Troubleshoot a bad image or a Service with no matching endpoints.
- [ ] Clean up the resources safely.

## Reflection

Answer these in your own words:

1. What is the difference between a container and a Pod?
2. What roles do the control plane and worker nodes play?
3. What happens after you apply a Kubernetes manifest?
4. Why are Deployments generally preferred to standalone Pods for application workloads?
5. What do you check first when a Pod is not running?

**Rule for this lab:** Try each task before looking up a solution. The goal is to become comfortable investigating Kubernetes, not memorising commands.
