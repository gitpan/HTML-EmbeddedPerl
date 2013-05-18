mod_mod_twepl.la: mod_mod_twepl.slo
	$(SH_LINK) -rpath $(libexecdir) -module -avoid-version  mod_mod_twepl.lo
DISTCLEAN_TARGETS = modules.mk
shared =  mod_mod_twepl.la
