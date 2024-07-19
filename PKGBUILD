pkgname=nbml-helper
pkgver=0.4
pkgrel=0
pkgdesc="Helper scripts and automatic hook for direct UEFI UKI boot setup without a standalone bootloader"
arch=('any')
license=('GPL-3.0-only')
depends=('systemd-ukify' 'booster' 'sbctl')
backup=('etc/nmbl-helper.conf' 'etc/ukify.conf')
source=('ukify-build.hook' 'rebuild-uki.sh' 'efi-install.sh' 'nmbl-helper.conf' 'ukify.conf')
sha512sums=(
  '245649861086d9bec53def8a58c1c93d03efa3ac16b6ea2026961b18d8c412927ea5b0c47e125be5546406e4781a75af9806cfe48e5377aabccdcb1cf435813c'
  '580366a5dc4d9ba1735e8afa5252a2ce8b0217e8d29b878221adb5c7e6fd82302b83ae02100ba17ceef650137e461512b6f8ddf4a18475b86601b4babae9ca93'
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
