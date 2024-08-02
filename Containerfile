FROM quay.io/fedora/fedora-bootc:40

ADD http://lab-02.rhts.eng.rdu.redhat.com/beaker/anamon3 /usr/local/sbin/anamon
RUN chmod 755 /usr/local/sbin/anamon
COPY beaker-harness.repo /etc/yum.repos.d/beaker-harness.repo
RUN dnf install -y restraint
