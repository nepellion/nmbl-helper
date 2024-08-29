pkgname=nmbl-helper
pkgver=0.9
pkgrel=1
pkgdesc="Helper scripts and automatic hook for direct UEFI UKI boot setup without a standalone bootloader"
arch=('any')
license=('GPL-3.0-only')
depends=('systemd-ukify' 'efibootmgr' 'grep')
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
  'aa2d0bc3f09991e42b8d165e80cdba8cec1c091d345d65c944ed5e673cab5599b45216061a99a5a3f23f9e207bf03d9f977d000784a3a75e8d5fe1af1fda31ce'
  '691e30d9cfaf320081be513f3dbed3d68f1776223907e826a14fc8418f40f59f1e3022c5fce5b9db0c035ac8633acebe8a18fec368a42627cfa83320ce679b4d'
  'a1de8db15403b659da11cd9f3b18163f931e07a65f356286f96fbcff9285b4c2e71c54562a0aa7d6456592830c2858c2f46c7c8d383fcdb8113e01f647c2a0e4'
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

  # Disable default booster hooks
  install -d -m755 "$pkgdir/etc/pacman.d/hooks"
  ln -s /dev/null "$pkgdir/etc/pacman.d/hooks/60-booster-remove.hook"
  ln -s /dev/null "$pkgdir/etc/pacman.d/hooks/90-booster-install.hook"
  ln -s /dev/null "$pkgdir/etc/pacman.d/hooks/zz-sbctl.hook"
}
