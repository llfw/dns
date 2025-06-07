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

NSUPDATE?=	nsupdate
NSUPDATE_FLAGS?=-g
NSDIFF?=	nsdiff
NSDIFFFLAGS?=	-Sserial -s ${MASTER}
DIFF?=

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

# Template variables for primary zones.
ZONE_PROCESS_FLAGS= \
	-Dttl=${TTL} \
	-Dnameservers="${NAMESERVERS}" \
	-Dsoa_mname=${SOA_MNAME} \
	-Dsoa_rname=${SOA_RNAME} \
	-Dsoa_serial=${SOA_SERIAL} \
	-Dsoa_refresh=${SOA_REFRESH} \
	-Dsoa_retry=${SOA_RETRY} \
	-Dsoa_expire=${SOA_EXPIRE} \
	-Dsoa_minimum=${SOA_MINIMUM}


# These zones are used for DN42.
DN42_ZONES= \
	dn42 \
	d.f.ip6.arpa \
	20.172.in-addr.arpa \
	21.172.in-addr.arpa \
	22.172.in-addr.arpa \
	23.172.in-addr.arpa \
	24.172.in-addr.arpa \
	25.172.in-addr.arpa \
	26.172.in-addr.arpa \
	27.172.in-addr.arpa \
	28.172.in-addr.arpa \
	29.172.in-addr.arpa \
	30.172.in-addr.arpa \
	31.172.in-addr.arpa

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

UNBOUND_SERVERS= \
	witch.le-fay.org \
	turnera.le-fay.org

UNBOUND_PROCESS_FLAGS= \
	-Dconfdir=/usr/local/etc/unbound \
	-Dmaster="${MASTER}" \
	-Dmaster_addr="${MASTER_ADDR}" \
	-Dlfnetworks="${LFNETWORKS}" \
	-Dlocal_zones="${ZONES}" \
	-Ddn42_zones="${DN42_ZONES}" \
	-Ddn42_master="${DN42_MASTER}"
UNBOUND_PROCESS_FLAGS.witch.le-fay.org=		-Dtls=yes
UNBOUND_PROCESS_FLAGS.turnera.le-fay.org=	-Dtls=yes

# The default target doesn't do anything.
all:
	@echo "Please specify a target:"
	@echo "  make diff           show diff between zone files and online zone"
	@echo "  make update-zones   update online zones"
	@echo "  make unbound-update build and install Unbound configs"

# Define the clean target to do nothing; we add dependencies to this below.
clean:

# File paths.
ZONEDIR=${.CURDIR}/zones
.PATH: ${ZONEDIR}
.OBJDIR: ${.CURDIR}/build
.SUFFIXES: .zone.erb .czone
.PHONY: all update-zones clean

### Define targets for primary zones.

.for zone in ${ZONES}
# Update this zone when running update-zones.
update-zones: ${zone}

# The zone itself is not a real file.
.PHONY: ${zone}

# How to build a processed zone from an ERB zonefile.
${zone:S,/,_,g}.czone: Makefile ${zone:S,/,_,g}.zone.erb
	${.CURDIR}/bin/process			\
		-Dzone=${zone}			\
		${ZONE_PROCESS_FLAGS}		\
		${ZONEDIR}/${zone:S,/,_,g}.zone.erb $@

# Take the built .czone file and send it to nsdiff.
# If DIFF is set, just print the diff instead of sending it to nsupdate.
${zone}: ${zone:S,/,_,g}.czone
.if ${DIFF} != ""
	@if ! ${NSDIFF} ${NSDIFFFLAGS} ${zone} ${.ALLSRC} >/dev/null 2>&1; then \
		tmpfile="$$(mktemp dns.XXXXXX)"; \
		${NSDIFF} ${NSDIFFFLAGS} ${zone} ${.ALLSRC} || true; \
		rm "$$tmpfile"; \
	fi
.else
	${NSDIFF} ${NSDIFFFLAGS} ${zone} $> | ${NSUPDATE} ${NSUPDATE_FLAGS}
.endif

# Delete the czone for this zone when cleaning.
clean-zone-${zone}:
	rm -f ${zone:S,/,_,g}.czone
clean: clean-zone-${zone}
.endfor

# For easy of use, 'make diff' runs update-zone with DIFF set.
.PHONY: diff

diff:
	@${MAKE} -C ${.CURDIR} DIFF=yes update-zones

### Unbound configuration files.

unbound-update:

.for server in ${UNBOUND_SERVERS}
update-unbound: update-unbound-${server}
update-unbound-${server}: unbound.conf.${server}
	@echo "updating ${server}"
unbound.conf.${server}: unbound.conf.erb
	${.CURDIR}/bin/process				\
		-Dservername=${server}			\
		${UNBOUND_PROCESS_FLAGS}		\
		${UNBOUND_PROCESS_FLAGS.${server}}	\
		$> $@
clean: clean-unbound-${server}
clean-unbound-${server}:
	rm -f ${.OBJDIR}/unbound.conf.${server}
.endfor
