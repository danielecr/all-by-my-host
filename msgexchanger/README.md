# IPC in Pods

This is an experiment of IPC communication between containers running on the same pod.

The idea is that if the containers share the pid namespace, then it is possible for them to communicate using
standard SYSV channels. If this is not the case (the pid namespace are not shared), the IPC is disallowed.

I run this to confirm or confute this idea.

Code in `src/msgpassing.c` come from man of msgrcv(2) / msgsnd(2). I just renamed `struct msgbuf` -> `msgbuffo`
because in alpine conflict name.

## First the failing test

Of course running by docker-compose (it means by containerd) in separated namespaces the two containers does not work

> . build_the_staff.sh

> . run-do-compo.sh

```sh
Starting myipc_msg-sender_1   ... done
Starting myipc_msg-receiver_1 ... done
Attaching to myipc_msg-sender_1, myipc_msg-receiver_1
msg-sender_1    | sent: a message at Thu Sep 28 10:23:04 2023
msg-sender_1    | 
msg-receiver_1  | No message available for msgrcv()
msg-receiver_1  | No message available for msgrcv()
msg-receiver_1  | No message available for msgrcv()
```

## Pushing image

I still have no internal repo for images so I think I have to push into the cri by running docker inside each node of my cluster.

Ubuntu suggest `podman-docker`, never tryed, but I give a chance