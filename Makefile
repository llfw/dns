NSDIFF=		nsdiff
NSDIFFFLAGS=	-Sserial -s hemlock.eden.le-fay.org
DIFF?=

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

all:
	@echo "Please specify a target:"
	@echo "  make diff           show diff between zone files and online zone"
	@echo "  make update-zones   update online zones"

.PATH: zones
.PHONY: all update-zones

.for zone in ${ZONES}
update-zones: ${zone}

.PHONY: ${zone}

${zone}: ${zone:S,/,_,g}.zone
.if ${DIFF} != ""
	@tmpfile="$$(mktemp dns.XXXXXX)"; \
	${NSDIFF} ${NSDIFFFLAGS} ${zone} $> \
		>"$$tmpfile" 2>&1 \
	|| cat "$$tmpfile"; \
	rm "$$tmpfile"
.else
	${NSDIFF} ${NSDIFFFLAGS} ${zone} $> | nsupdate -g
.endif
.endfor

.PHONY: diff

diff:
	@${MAKE} update-zones DIFF=yes
