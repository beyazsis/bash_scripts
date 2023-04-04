#!/bin/bash

echo Arch Linux Kurulumuna Hosgeldiniz!
dizi=""
$rootYolu
$efiMi
$hostnameV
$usernameV
$rootpassV
$userpassV
$desktopEnv

scriptliChroot()
{
    #öncelikle devam scriptinin çalışması için /mnt dizinine kopyalayalım
    cp archerChroot.sh /mnt
    #nm-applet için de aynısını yapalım
    cp nm-applet.desktop /mnt
    #ardından arch-chroot komutunu bu script ile başlaması için yazalım
    mount /dev/"$rootYolu"1 /mnt/boot
    arch-chroot /mnt ./archerChroot.sh #güle güle!
    #bir dakika... Zaten sonraki script bittiğinde exit ile bu script devam edecek
    #o zaman bir şeyler daha ekleyeyim
    rm /mnt/archerChroot.sh
    echo 'Yükleme Tamamlandı! İyi günlerde kullanmanız dileğiyle.'
    echo 'reboot yazarak cihazı yeniden başlatın ve yükleme medyasını çıkartın.'
}

installBase()
{
    #sunucumuzu belirleyelim
    reflector --country Turkey --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    if [ $efiMi = true ] 
    then
        #bu komut ile her şeyi yükleyebiliriz chroot olmadan!
        pacstrap -K /mnt base linux linux-firmware grub efibootmgr nano networkmanager wpa_supplicant mesa alsa
        #fstab da oluşturalım
        genfstab -U /mnt >> /mnt/etc/fstab
        #!!!Dikkat buradan sonra bu scriptin görevi bitmiş ve devam scripti chroot ortamında otomatik olarak çalıştırılacaktır.
        scriptliChroot

    else
        #bu komut ile her şeyi yükleyebiliriz chroot olmadan!
        pacstrap -K /mnt base linux linux-firmware grub nano networkmanager wpa_supplicant mesa alsa
        genfstab -U /mnt >> /mnt/etc/fstab
        #!!!Dikkat buradan sonra bu scriptin görevi bitmiş ve devam scripti chroot ortamında otomatik olarak çalıştırılacaktır.
        scriptliChroot

    fi
}   

diskPartition()
{
    if [ $efiMi = true ] 
    then
        #Bölüm şemasını gpt yapmak birimdeki tüm bölümleri silecektir ve elimizde free space kalacaktır sadece.
        parted /dev/"$rootYolu" --script mklabel gpt
        #Bu komut ile grub'un yükleneceği 512 mb efi bölümü oluşturulur.
        parted /dev/"$rootYolu" --script mkpart "EFI system partition" fat32 1MiB 513MiB
        #Oluşan bölümün önyüklemesini açmak
        parted /dev/"$rootYolu" --script set 1 esp on
        #esp yaptık ama legacy ise boot bayrağını da etkinleştirelim. İkisinin aynı anda olmasının bir zararı yok ne de olsa.
        parted /dev/"$rootYolu" --script set 1 boot on
        #Geri kalan her şeyi root bölümü yapalım bu komut ile. Takas alanına gerek yok gibi :d Zaten eskide kaldı o işler
        parted /dev/"$rootYolu" --script mkpart "root" ext4 513MiB 100%
        #!!!Dikkat!!!
        #efi bölümünnü numarası 1
        #root bölümünün numarası 2
        #ESP bölümünü fat32 ile biçimlendirmek.
        mkfs.fat -F 32 /dev/"$rootYolu"1
        #root bölümünü ext4 ile biçimlendirmek
        mkfs.ext4 /dev/"$rootYolu"2
        #Bölümleri biçimlendirme işlemi bitti. Başka bir fonksiyonda bölümleri işlemek için /mnt ye bağlayalım
        #gerçi buradan devam edelim
        #root bölümünü mnt ye bağladık
        mount /dev/"$rootYolu".2 /mnt
        #efi bölümünü /mn/boot dizinine bağladık
        mkdir /mnt/boot
        mount /dev/"$rootYolu".1 /mnt/boot
        #ardından base sistemi kurmak için sonraki fonksiyonumuza geçelim
    else
        #mbr için tek bölüm yapmak yeterli.
        parted /dev/"$rootYolu" --script mklabel mbr
        #ama yine de boot olarak etiketlemek gerek
        parted /dev/"$rootYolu" --script set 1 boot on
        #bölümü biçimlendirelim
        mkfs.ext4 /dev/"$rootYolu"1
        #bölümü bağlayalım
        mount /dev/"$rootYolu"1 /mnt
        #ardından base sistemi kurmak için sonraki fonksiyonumuza geçelim
    fi
}

bilgiTopla7()
{
    echo
    echo -e "   \033[31mÖzet:\033[m"
    echo "  kullanı adı : $usernameV"
    echo "  makine adı: $hostnameV"
    echo "  Masaüstü ortamı: $desktopEnv"
    echo "  Kurulacak disk:"
    lsblk /dev/"$rootYolu"
    echo
    echo -e "   \033[31m!!!Dikkat!!! Bundan sonrasında geri dönüş yoktur!\033[m"
    echo -e "   \033[31mKurulumu başlatmak için\033[m evet \033[31myazınız\033[m"
    read secim
    case $secim in
        evet)
            echo "      Kuruluma başlanıyor!";
            echo -e "   \033[31mAygıt Bağlantısı Kesmeyin Lütfen\033[m";
            sleep 2;
            diskPartition;;
        hayır)
            echo "      Kurulum iptal edildi";
            exit;;
        *)
            echo "Giriş tanınmadı. evet yada hayır ile yanıt veriniz.";
            bilgiTopla7;;
    esac
}

bilgiTopla6()
{
    echo "Hangi grafiksel arayüzü kullanmak istersiniz? 1, 2, 3 şeklinde seçiniz."
    select secim in xfce kde gnome noGUI
    do
        case $secim in
            "xfce")
                echo "xfce seçildi";
                desktopEnv="xfce";
                bilgiTopla7;;
            "kde")
                echo "kde seçildi";
                desktopEnv="kde";
                bilgiTopla7;;
            "gnome")
                echo "gnome seçildi";
                desktopEnv="gnome";
                bilgiTopla7;;
            "noGUI")
                echo "Grafiksel arayüz kurulmayacak";
                desktopEnv="noGUI";
                bilgiTopla7;;
            *)
                echo "Anlayamadım?"
                bilgiTopla6

        esac
    done

}


bilgiTopla5()
{
    echo "Kullanıcı parolası belirleyiniz"
    read -e -p "kullanıcı parolası:" userpassV
    sleep 1
    echo "tekrar giriniz"
    read -e -p "tekrar:" cerez
    sleep 1
    if [ "$userpassV" = "$cerez" ]
    then
        bilgiTopla6
    else
        echo şifreler eşleşmiyor. Tekrar giriniz lütfen.
        sleep 1
        bilgiTopla5
    fi
}

bilgiTopla4()
{
    echo "root parolası belirleyiniz"
    read -e -p "root parolası:" rootpassV
    sleep 1
    echo "tekrar giriniz"
    read -e -p "tekrar:" cerez
    if [ "$rootpassV" = "$cerez" ]
    then
        bilgiTopla5
    else
        echo şifreler eşleşmiyor. Tekrar giriniz lütfen.
        bilgiTopla4
    fi
}

bilgiTopla3()
{
    echo "Username Belirleyiniz (Türkçe karakterler kullanmayınız lütfen)"
    read -e -p "username:" usernameV
    sleep 1
    echo "Usernae: $usernameV olarak belirlendi. Kabul ediyor musunuz?"
    read -e -p "E/H?" secim
        case $secim in
            [Ee])
                bilgiTopla4;;
            [Hh])
                bilgiTopla3;;
            *)
                echo "E veya H harfini kullanarak cevap veriniz.";
                bilgiTopla3;;
        esac
}


bilgiTopla2()
{
    echo "Hostname Belirleyiniz (Türkçe karakterler kullanmayın lütfen)"
    read -e -p "hostname:" hostnameV
    sleep 1
    echo "Hostname: $hostnameV olarak belirlendi. Kabul ediyor musunuz?"
    read -e -p "E/H?" secim
        case $secim in
            [Ee])
                bilgiTopla3;;
            [Hh])
                bilgiTopla2;;
            *)
                echo "E veya H harfini kullanarak cevap veriniz.";
                bilgiTopla3;;

        esac
}

bilgiTopla()
{
    echo Arch Linux\'ü hangi depolama birimine yükleyeceksiniz?
    echo sda, sdb veya sdc şeklinde yazarak belirtiniz.
    echo
    echo şu depolama birimleri bulundu
    ls /dev/sd*[a-z]
    read -e -p "birim adı: " rootYolu
    if [ -e /dev/$rootYolu ]
    then
        echo Tamamdır!
        echo
        echo
    else
        echo /dev/$rootYolu bulunamıyor!
        echo adresi kontrol edip tekrar deneyiniz.
        lsblk
        bilgiTopla
    fi
    echo Bu script seçtiğiniz tüm depolama birimindeki verileri imha edip tamamına arch linux yükleyecektir
    echo henüz depolama biriminizde bir değişiklik yapılmadı
    sleep 2
    echo
    sleep 1
    dmesg | grep -q "EFI v" #sistem EFI mi?
    if [ $? -eq 0 ]
    then
        echo EFI tespit edildi!
        sleep 1
        echo Bir yanlışlık olduğunu düşünüyorsanız legacy kurulum ile devam etmek için soru işareti yazıp entera basın.
        echo Bir fikriniz yoksa muhtemelen sorun yok demektir. Enter\'a basıp devam ediniz.
        read secim
        case $secim in
            [?])
                echo Legacy bios ile devam ediliyor...;
                sleep 1;
                efiMi=false;;
            *)
                echo EFI ile devam ediliyor...;
                efiMi=true
                sleep 1;;
        esac
    else
        echo Legacy-BIOS tespit edildi!
        sleep 1
        echo Bir yanlışlık olduğunu düşünüyorsanız EFI kurulum ile devam etmek için soru işareti yazıp entera basın.
        echo Bir fikriniz yoksa muhtemelen sorun yok demektir. Enter\'a basıp devam ediniz.
        read secim
        case $secim in
            [?])
                echo EFI bios ile devam ediliyor...;
                efiMi=true
                sleep 1;;
            *)
                echo Legacy ile devam ediliyor...;
                efiMi=false
                sleep 1;;
        esac
    fi
    if [ $efiMi = true ]
    then
        echo GPT bölüm şeması kullanılacak...
    else
        echo MBR disk ile devam ediliyor...
    fi
    sleep 1
    bilgiTopla2
}

yazKontBitir()
{
    screenfetch
    if [ "$dizi" = "" ]
    then
        echo
        echo
        bilgiTopla
    else
    echo
    echo
    echo $dizi
    echo
    echo yukarıda ki yazılımlar yüklenecek...
    pacman -S $dizi && bilgiTopla
    fi
}

pacmanDizisi()
{
    dizi+=$1
    dizi+=" "
}

yazilimKontrol()
{   
    if [ "$(command -v pacman)" ]
    then
        echo "pacman     ------------------- [VAR]"
    else
        echo !!!BU SCRIPT ARCH LINUX VEYA ARCH LINUX TABANLI BİR DAĞITIMDA ÇALIŞABİLİR!!!
        echo arch linux kurulum medyasını kullanmanızı tavsiye ederiz.
        echo daha fazla bilgi için abacitaha@gmail.com ya da beyazsis github hesabı ile iletişime geçebilirsiniz. 
        exit
    fi
    #####################################3
    if [ "$(command -v screenfetch)" ]
    then
        echo "screenfetch    ------------------- [VAR]"
    else
        echo "screenfetch    ------------------- [YÜKLENECEK]"
        pacmanDizisi screenfetch
    fi
    ##########################
    if [ "$(command -v nano)" ]
    then
        echo "nano   ------------------- [VAR]"
    else
        echo "nano   ------------------- [YÜKLENECEK]"
        pacmanDizisi nano
    fi
    yazKontBitir
}

starter() 
{
    #kullanıcı root mu?
    if [ "$(id -u)" -eq 0 ] 
    then
        yazilimKontrol
    else
        echo ARCHER root olarak çalıştırılmalıdır.
    fi
}


starter