pkgname=nmbl-helper
pkgver=0.5
pkgrel=0
pkgdesc="Helper scripts and automatic hook for direct UEFI UKI boot setup without a standalone bootloader"
arch=('any')
license=('GPL-3.0-only')
depends=('systemd-ukify' 'efibootmgr')
optdepends=(
  'booster: Automatic initramfs image creation (recommended)'
  'sbctl: Secure Boot signing'
)
backup=(
  'etc/nmbl-helper.conf'
  'etc/ukify.conf'
)
source=(
  'ukify-build.hook'
  'rebuild-uki.sh'
  'efi-install.sh'
  'nmbl-helper.conf'
  'ukify.conf'
)
sha512sums=(
  'b1d77c83dfc239603a0d5ca2b0b183c302563c5cfe44dde7dfd8c9318a3e3c55e141d47cbc59c9192768141c0521f5bc728fa36ca571ba5ae2a41e088aa6d627'
  '89e95c733759cff680236718e5afe64f0237db874ffd1e8c9271e6cfbb5e200c21323de448fd959026b31d41ca4625c65a220f508950f291836491dd2821f02e'
  '821ca5d89387acfcf30f677130316039ebc37179fcab574ffa24c3c558f874b9a155a41b793812ef61aa8fe5b2cfbccf9aab819c39e07c22ba4a87f25c3b94ee'
  '8749834ce614c984c8a84634cb524f80dfc98549ecbf358fc48925eb0be4d7ed5e2573d1b2070c12d5afb9a4577064568b75bb4c14d19e085eb3ed89b5564146'
  'b66116db1da77599bd6e699ed35dc0954dab86bcd8ae7698aec1c613ead17413157ed464c4863fbffebfe5d3c389ed1acde6332384c43ea4db9dcb97a7f7ff72'
)

package() {
  # Configuration files
  install -d -m755 "$pkgdir/etc/nmbl-helper.d"
  install -D -m644 nmbl-helper.conf "$pkgdir/etc/nmbl-helper.conf"
  install -D -m644 ukify.conf "$pkgdir/etc/ukify.conf"

  # Hooks
  install -D -m644 ukify-build.hook "$pkgdir/usr/share/libalpm/hooks/99-ukify-build.hook"

  # Scripts
  install -D -m755 rebuild-uki.sh "$pkgdir/usr/lib/nmbl-helper/rebuild-uki.sh"
  install -D -m755 efi-install.sh "$pkgdir/usr/lib/nmbl-helper/efi-install.sh"
}
