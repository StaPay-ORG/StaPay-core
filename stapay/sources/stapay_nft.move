module stapay::stapay_nft {
    use std::string::{String, utf8};
    use sui::display;
    use sui::event;
    use sui::object;
    use sui::package;
    use sui::table;
    use sui::table::Table;
    use sui::vec_set;
    use sui::vec_set::VecSet;

    public struct STAPAYNFT has key, store {
        id: UID,
        nft_id: u64,
        name: String,
        amount: u64,
        service: String,
        third_party_service: String,
        image_url: String,
        creator: address,
        recipient: address
    }

    public struct STAPAY_NFT has drop {}

    public struct MintRecord has key {
        id: UID,
        record: Table<address, u64>
    }

    public struct ServiceMintRecord has key {
        id: UID,
        record: Table<address, VecSet<String>>
    }

    // 事件
    public struct NFTMinted has copy, drop {
        object_id: ID,
        amount: u64,
        service: String,
        third_party_service: String,
        name: String,
        creator: address,
    }

    public struct ServiceMintRecordChanged has copy, drop {
        recipient: address,
        service_mint_record: VecSet<String>,
    }

    // 错误码
    const EDontMintAgain: u64 = 0;
    const ENotEnoughSupply: u64 = 1;
    const MAX_SUPPLY: u64 = 46;

    fun init(otw: STAPAY_NFT, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"amount"),
            utf8(b"service"),
            utf8(b"third_party_service"),
            utf8(b"image_url"),
            utf8(b"description"),
            utf8(b"creator")];
        let values = vector[
            utf8(b"{name} #{nft_id}"),
            utf8(b"{amount}"),
            utf8(b"{service}"),
            utf8(b"{third_party_service}"),
            utf8(b"{image_url}"),
            utf8(b"A NFT for your stapay stake"),
            utf8(b"{creator}"),
        ];
        // let mint_record = MintRecord {
        //     id: object::new(ctx),
        //     record: table::new<address, u64>(ctx)
        // };

        let service_mint_record = ServiceMintRecord {
            id: object::new(ctx),
            record: table::new<address, VecSet<String>>(ctx)
        };
        let publisher = package::claim(otw, ctx);
        let mut display = display::new_with_fields<STAPAYNFT>(&publisher, keys, values, ctx);
        display::update_version(&mut display);
        transfer::public_transfer(publisher, ctx.sender());
        transfer::public_transfer(display, ctx.sender());
        transfer::share_object(service_mint_record);
    }

    public entry fun mint_for_service_user(
        service_mint_record: &mut ServiceMintRecord,
        name: String,
        amount: u64,
        service: String,
        third_party_service: String,
        user_image_url: String,
        service_image_url: String,
        user_recipient: address,
        service_recipient: address,
        ctx: &mut TxContext
    ) {
        mint(service_mint_record, name, amount, service, third_party_service, user_image_url, user_recipient, ctx);
        mint(service_mint_record, name, amount, service, third_party_service, service_image_url, service_recipient, ctx);
    }

    public entry fun mint(
        service_mint_record: &mut ServiceMintRecord,
        name: String,
        amount: u64,
        service: String,
        third_party_service: String,
        image_url: String,
        recipient: address,
        ctx: &mut TxContext
    ) {
        // 判断，该地址针对该service是否铸造过nft
        if (table::contains(&service_mint_record.record, recipient)) {
            //该地址如果铸造过NFT，检查有没有铸造过该service的
            // assert!(
            //     !vec_set::contains(table::borrow(&service_mint_record.record, recipient), &service),
            //     EDontMintAgain
            // );
            // 该地址如果没有铸造过NFT，则添加记录
            let service_record = table::borrow_mut(&mut service_mint_record.record, recipient);
            vec_set::insert(service_record, service);
        }else {
            let mut service_record = vec_set::empty<String>();
            vec_set::insert(&mut service_record, service);
            table::add(&mut service_mint_record.record, recipient, service_record);
        };

        event::emit(ServiceMintRecordChanged {
            recipient: recipient,
            service_mint_record: *table::borrow(&service_mint_record.record, recipient),
        });
        // assert!(!table::contains(&third_party_mint_record.record, recipient), EDontMintAgain);

        let nft_id: u64 = table::length(&service_mint_record.record) + 1;
        // table::add(&mut mint_record.record, recipient, nft_id);
        // assert!(nft_id <= MAX_SUPPLY, ENotEnoughSupply);

        let nft = STAPAYNFT {
            id: object::new(ctx),
            nft_id: nft_id,
            name,
            amount,
            service,
            third_party_service,
            image_url,
            creator: ctx.sender(),
            recipient: recipient
        };

        event::emit(NFTMinted {
            object_id: object::id(&nft),
            name: name,
            amount,
            service,
            third_party_service,
            creator: ctx.sender(),
        });

        transfer::public_transfer(nft, recipient);
    }

    public entry fun burn(service_mint_record: &mut ServiceMintRecord, nft: STAPAYNFT) {
        let service_record = table::borrow_mut(&mut service_mint_record.record, nft.recipient);
        vec_set::remove(service_record, &nft.service);
        //如果记录为空，删除该集合
        if (vec_set::is_empty(service_record)) {
            table::remove(&mut service_mint_record.record, nft.recipient);
            event::emit(ServiceMintRecordChanged {
                recipient: nft.recipient,
                service_mint_record: vec_set::empty<String>(),
            });
        }else {
            event::emit(ServiceMintRecordChanged {
                recipient: nft.recipient,
                service_mint_record: *table::borrow(&service_mint_record.record, nft.recipient),
            });
        };


        let STAPAYNFT {
            id, nft_id, name, amount, service,
            third_party_service, image_url, recipient, creator
        } = nft;
        object::delete(id);
    }
}