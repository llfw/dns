# This source code is released into the public domain.
#
# Primary makefile for DNS management.


### Our local master server.
MASTER=		hemlock.eden.le-fay.org
MASTER_ADDR!=	getaddrinfo -f inet6 -p tcp -t stream ${MASTER} \
			| awk '{ print $$4 }'


### Default SOA values.
# Serial is always 1; nsdiff handles this magically.
SOA_MNAME=	${MASTER}.
SOA_RNAME=	hostmaster.le-fay.org.
SOA_SERIAL=	1
SOA_REFRESH=	1d
SOA_RETRY=	1h
SOA_EXPIRE=	2w
SOA_MINIMUM=	5m
# Default value for $TTL.
TTL=		1h
# Nameservers to use for Internet zones.
NAMESERVERS=	ns1.le-fay.org \
		ns2.le-fay.org \
		ns3.le-fay.org


### The DN42 master server.
DN42_MASTER=	fd42:4242:2601:ac53::1


# The zones we serve.
ZONES=	le-fay.org \
	le-fay.org.uk \
	le-fay.dn42 \
	rt.uk.eu.org \
	b.6.0.b.3.8.a.0.b.5.d.f.ip6.arpa \
	e.1.0.0.0.8.c.1.6.0.a.2.ip6.arpa \
	b.6.0.0.8.9.0.1.0.0.a.2.ip6.arpa \
	a.4.0.4.8.a.b.0.1.0.0.2.ip6.arpa \
	5.1.0.4.8.a.b.0.1.0.0.2.ip6.arpa \
	5.b.a.a.0.b.8.0.1.0.0.2.ip6.arpa \
	117.73.187.81.in-addr.arpa \
	160-175.96.2.81.in-addr.arpa \
	192-207.47.187.81.in-addr.arpa \
	0/26.76.23.172.in-addr.arpa \
	18.198.in-addr.arpa

# These zones are used for DN42.
DN42_ZONES= \
	dn42 \
	d.f.ip6.arpa \
	20.172.in-addr.arpa 21.172.in-addr.arpa 22.172.in-addr.arpa \
	23.172.in-addr.arpa 24.172.in-addr.arpa 25.172.in-addr.arpa \
	26.172.in-addr.arpa 27.172.in-addr.arpa 28.172.in-addr.arpa \
	29.172.in-addr.arpa 30.172.in-addr.arpa 31.172.in-addr.arpa

# Our local networks.
# TODO: Generate these from LDAP.
LFNETWORKS= \
	2001:8b0:aab5::/48 \
	81.187.47.192/28 \
	81.2.96.160/28 \
	81.187.73.117/32 \
	2a00:1098:6b::/48 \
	2001:ba8:4015::/48 \
	2001:ba8:404a::/48 \
	fd5b:a83:b06b::/48 \
	172.16.0.0/12 \
	10.0.0.0/8 \
	198.18.0.0/15


#######################################################################
# Unbound configuration for resolvers.

# All servers which run Unbound.
UNBOUND_SERVERS?= \
	hemlock.eden.le-fay.org \
	fuchsia.eden.le-fay.org \
	yarrow.le-fay.org \
	amaranth.le-fay.org \
	witch.le-fay.org \
#	turnera.le-fay.org

# Forwarder addresses for Unbound forwarders.
UNBOUND_FORWARDERS?= \
	2001:8b0:aab5:c401::1:3 \
	2001:8b0:aab5:c401::1:4

# -Dforwarder means this server forwards queries to ${UNBOUND_FORWARDERS}.
# -Dnolocal means this server doesn't have a copy of our local zones.
#
UNBOUND_PROCESS_FLAGS.hemlock.eden.le-fay.org=	-Dnolocal=yes -Dforwarder=yes
UNBOUND_PROCESS_FLAGS.amaranth.le-fay.org=	-Dnolocal=yes
UNBOUND_PROCESS_FLAGS.yarrow.le-fay.org=	-Dnolocal=yes
UNBOUND_PROCESS_FLAGS.witch.le-fay.org=		-Dtls=yes
UNBOUND_PROCESS_FLAGS.turnera.le-fay.org=	-Dtls=yes


#######################################################################
# Knot configuration for primary servers.
#

# Global options.
KNOT_SERVERS?= \
	yarrow.le-fay.org \
	amaranth.le-fay.org \
	fuchsia.eden.le-fay.org

KNOT_PROCESS_FLAGS= \
	-Dmaster=${MASTER} \
	-Dmaster_addr=${MASTER_ADDR} \
	-Dzones="${ZONES}"

# Server-specific options.
KNOT_LISTEN.yarrow.le-fay.org= \
	2a00:1098:6b:100::2@53 \
	176.126.243.79@53

KNOT_LISTEN.amaranth.le-fay.org= \
	2001:ba8:4015:100::2@53 \
	185.73.44.74@53

KNOT_LISTEN.fuchsia.eden.le-fay.org= \
	2001:8b0:aab5:4::9@53 \
	81.187.47.195@53 \
	fd5b:a83:b06b:4::9@53 \
	fd5b:a83:b06b:600::5@53


#######################################################################
# The default target doesn't do anything.
#

all:
	@echo "Please specify a target:"
	@echo "  make diff           show diff between zone files and online zone"
	@echo "  make update-zones   update online zones"
	@echo "  make unbound        build and install Unbound configs"
	@echo "  make knot           build and install Knot configs"
.PHONY: all

# Individual targets add dependencies to clean.
clean:
.PHONY: clean

.include "Makefile.inc.knot"
.include "Makefile.inc.unbound"
.include "Makefile.inc.zones"

# File paths.
.PATH: ${ZONEDIR}
.OBJDIR: ${.CURDIR}/build

BINDIR=		${.CURDIR}/bin
PROCESS=	${BINDIR}/process
