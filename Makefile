PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DATADIR ?= $(PREFIX)/share
SYSTEMD_USER_DIR ?= $(DATADIR)/systemd/user
BASH_COMPLETION_DIR ?= $(DATADIR)/bash-completion/completions

.PHONY: install uninstall check

install:
	install -Dm755 bin/virt-mic-paw "$(DESTDIR)$(BINDIR)/virt-mic-paw"
	install -Dm644 systemd/user/virt-mic-paw.service.in "$(DESTDIR)$(SYSTEMD_USER_DIR)/virt-mic-paw.service"
	install -Dm644 completions/virt-mic-paw.bash "$(DESTDIR)$(BASH_COMPLETION_DIR)/virt-mic-paw"
	install -Dm644 README.md "$(DESTDIR)$(DATADIR)/doc/virt-mic-paw/README.md"
	install -Dm644 docs/how-it-works.md "$(DESTDIR)$(DATADIR)/doc/virt-mic-paw/how-it-works.md"
	install -Dm644 docs/troubleshooting.md "$(DESTDIR)$(DATADIR)/doc/virt-mic-paw/troubleshooting.md"
	install -Dm644 docs/security.md "$(DESTDIR)$(DATADIR)/doc/virt-mic-paw/security.md"
	install -Dm644 LICENSE "$(DESTDIR)$(DATADIR)/licenses/virt-mic-paw/LICENSE"

uninstall:
	rm -f "$(DESTDIR)$(BINDIR)/virt-mic-paw"
	rm -f "$(DESTDIR)$(SYSTEMD_USER_DIR)/virt-mic-paw.service"
	rm -f "$(DESTDIR)$(BASH_COMPLETION_DIR)/virt-mic-paw"
	rm -rf "$(DESTDIR)$(DATADIR)/doc/virt-mic-paw"
	rm -rf "$(DESTDIR)$(DATADIR)/licenses/virt-mic-paw"

check:
	bash -n bin/virt-mic-paw install.sh uninstall.sh tools/dev-check.sh tools/publish-github.sh
	@command -v shellcheck >/dev/null 2>&1 && shellcheck bin/virt-mic-paw install.sh uninstall.sh tools/*.sh || echo "shellcheck not installed; skipped"
