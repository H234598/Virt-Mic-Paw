Name:           virt-mic-paw
Version:        0.1.0
Release:        1%{?dist}
Summary:        Virtual mixed microphone for Fedora PipeWire/PulseAudio

License:        MIT
URL:            https://github.com/H234598/Virt-Mic-Paw
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       bash
Requires:       pulseaudio-utils
Requires:       systemd
Recommends:     pavucontrol

%description
Virt-Mic-Paw creates a virtual input device that mixes a real microphone and
system audio from the selected output monitor. It is intended for Fedora systems
using PipeWire with PulseAudio compatibility.

%prep
%autosetup

%build

%install
%make_install PREFIX=%{_prefix}

%files
%license LICENSE
%doc README.md docs/how-it-works.md docs/troubleshooting.md docs/security.md CHANGELOG.md
%{_bindir}/virt-mic-paw
%{_userunitdir}/virt-mic-paw.service
%{_datadir}/bash-completion/completions/virt-mic-paw

%changelog
* Mon Jun 01 2026 H234598 <noreply@example.com> - 0.1.0-1
- Initial package
