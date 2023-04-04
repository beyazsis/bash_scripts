#!/bin/bash


$hostnameV
$rootpassV
$tamYol

sonAyarlar()
{
    #network manager etkinleştirelim
    systemctl enable NetworkManager
    pacman --no-confirm -S pulseaudio
    touch /home/"$hostnameV"/Hehehe
    echo "Benim yükleme scriptimi kullandığınız için teşekkür ederim! -BeyazSis" >> /home/"$hostnameV"/Hehehe
    echo
    echo
    echo "  Yükleme Başarıyla Tamamlandı! Bilgisayarınızı yeniden başlatmak için reboot yazınız."
    echo "  Ya da durun reboot yazmayın ben yazayım sizin yerinize"
    sleep 1
    echo "  Kurulum medyanızı çıkartın yada çıkartmayın. Çıkartmazsanız bios dan yüklediğiniz diskin önyüklemesini öne almayı unutmayın yoksa yükleme medyasından tekrar boot edersiniz."
    read -p "Tamamsanız enter tuşuna basınız..."
    sleep 1
    echo "o zaman reboot"
    sleep 1
    reboot

}

arayuzKurulumu()
{
    echo "Hangi grafiksel arayüzü kullanmak istersiniz? 1, 2, 3 şeklinde seçiniz."
    select secim in xfce kde gnome noGUI
    do
        case $secim in
            "xfce")
                echo "xfce seçildi";
                pacman --no-confirm -S xfce4 xfce4-goodies lxdm nm-applet;
                systemctl enable lxdm;
                #nm-applet i otomatik çalıştırmaya ekleyelim
                mkdir -p /etc/xdg/autostart
                cp nm-applet.desktop /etc/xdg/autostart
                sonAyarlar;;
            "kde")
                echo "kde seçildi";
                pacman --no-confirm -S plasma sddm;
                systemctl enable sddm;
                sonAyarlar;;
            "gnome")
                echo "gnome seçildi";
                pacman --no-confirm -S gnome gnome-extra gdm;
                systemctl enable gdm;
                sonAyarlar;;
            "noGUI")
                echo "Grafiksel arayüz kurulmayacak";
                sonAyarlar;;
            *)
                echo "Anlayamadım?"
                arayuzKurulumu

        esac
    done
}

kullaniciEkle()
{
    echo "Username Belirleyiniz (Türkçe karakterler kullanmayınız lütfen)"
    read -e -p "username:" usernameV
    sleep 1
    echo "Usernae: $usernameV olarak belirlendi. Kabul ediyor musunuz?"
    read -e -p "E/H?" secim
        case $secim in
            [Ee])
                useradd -m -g users -G optical,storage,wheel,video,audio,users,power,network,log -s /bin/bash "$usernameV";
                echo "kullanı parolanızı giriniz:";
                passwd "$usernameV";;
            [Hh])
                kullaniciEkle;;
            *)
                echo "E veya H harfini kullanarak cevap veriniz.";
                kullaniciEkle;;
        esac
}

bootLoader()
{
    if [ $? -eq 0 ]
    then
        echo "EFI"
        grub-install --target=x86_64-efi --efi-directory=/boot
    else
        echoo "legacy"
        #grubun yükleneceği diskin yolunu tespit etmek için içinde bulunduğumuz dizinin hangi depolama biriminde açık olduğunu buluyoruz
        tamYol=$(df -P . | awk 'END{print $1}')
        grub-install "$tamYol"
    fi
}

rootPass()
{
    echo "Root parolası belirleyiniz"
    read -e -p "root parolası:" rootpassV
    sleep 1
    echo "tekrar giriniz"
    read -e -p "tekrar:" cerez
    if [ "$rootpassV" = "$cerez" ]
    then
        passwd
        echo "Grub kurulumu başlatılıyor..."
        sleep 2
        bootLoader
    else
        echo şifreler eşleşmiyor. Tekrar giriniz lütfen.
        rootPass
    fi
}

sistemAyarlari()
{
    #initramfs dosyamızı oluşturalım
    mkinitcpio -P
}

hostname()
{
    echo "Hostname Belirleyiniz (Türkçe karakterler kullanmayın lütfen)"
    read -e -p "hostname:" hostnameV
    sleep 1
    echo "Hostname: $hostnameV olarak belirlendi. Kabul ediyor musunuz?"
    read -e -p "E/H?" secim
        case $secim in
            [Ee])
                touch /etc/hostname
                echo "$hostnameV" >> /etc/hostname;; 
            [Hh])
                hostname;;
            *)
                echo "E veya H harfini kullanarak cevap veriniz.";
                hostname;;

        esac
}   


starter()
{
    #sistemi yerelleştirelim
    ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
    #zamanı senkronize edelim
    hwclock --systohc
    #dilimizi şeçelim
    echo -e '\ntr_TR.UTF-8 UTF-8' >> /etc/locale.gen 
    echo -e '\nen_US.UTF-8 UTF-8' >> /etc/locale.gen
    locale-gen
    touch /etc/locale.conf
    echo -e '\nLANG=tr_TR.UTF-8' >> /etc/locale.conf
    echo -e "\nKEYMAP=trq" >> /etc/vconsole.conf
}

