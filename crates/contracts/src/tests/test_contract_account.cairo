use alexandria_storage::list::{List, ListTrait};
use contracts::tests::utils::constants::EVM_ADDRESS;
use evm::model::contract_account::{ContractAccount, ContractAccountTrait};
use starknet::{storage_base_address_from_felt252, Store};
use utils::storage::{compute_storage_base_address};
use utils::traits::{StoreBytes31, StorageBaseAddressIntoFelt252};

#[test]
#[available_gas(2000000)]
fn test_nonce() {
    let evm_address = EVM_ADDRESS();
    let mut ca = ContractAccountTrait::new(evm_address);
    assert(ca.nonce().unwrap() == 0, 'initial nonce not 0');
    ca.increment_nonce();
    assert(ca.nonce().unwrap() == 1, 'nonce not incremented');
}

#[test]
#[available_gas(2000000)]
fn test_balance() {
    let evm_address = EVM_ADDRESS();
    let mut ca = ContractAccountTrait::new(evm_address);
    assert(ca.balance().unwrap() == 0, 'initial balance not 0');
    ca.set_balance(1);
    assert(ca.balance().unwrap() == 1, 'balance not incremented');
}

#[test]
#[available_gas(20000000)]
fn test_contract_storage() {
    let evm_address = EVM_ADDRESS();
    let mut ca = ContractAccountTrait::new(evm_address);
    let key = u256 { low: 10, high: 10 };
    assert(ca.storage_at(key).unwrap() == 0, 'initial key not null');
    let value = u256 { low: 0, high: 1 };
    ca.set_storage_at(key, value);
    let value_read = ca.storage_at(key).unwrap();
    assert(value_read == value, 'value not read correctly');
}

#[test]
#[available_gas(20000000)]
fn test_store_bytecode_word_not_full() {
    let byte_array: Array<u8> = array![0x01, 0x02, 0x03, // 3 elements
    ];
    let evm_address = EVM_ADDRESS();
    let mut ca = ContractAccountTrait::new(evm_address);
    ca.store_bytecode(byte_array.span());

    // Address at which the bytecode should be stored
    let data_addr = compute_storage_base_address(
        selector!("contract_account_bytecode"), array![evm_address.into()].span()
    );
    let pending_word_addr = storage_base_address_from_felt252(data_addr.into() - 2_felt252);
    let pending_word_len_addr = storage_base_address_from_felt252(data_addr.into() - 1_felt252);

    let pending_word = Store::<felt252>::read(0, pending_word_addr).unwrap();
    let pending_word_len = Store::<u32>::read(0, pending_word_len_addr).unwrap();
    let list: List<bytes31> = Store::<List<bytes31>>::read(0, data_addr).unwrap();
    let bytecode: ByteArray = ByteArray {
        data: list.array(), pending_word: pending_word, pending_word_len: pending_word_len
    };

    assert(bytecode.pending_word_len == 3, 'pending word not 3');
    assert(bytecode.pending_word == 0x010203, 'pending word not restituted');
    assert(bytecode.data.len() == 0, 'data not empty');
}


#[test]
#[available_gas(20000000)]
fn test_store_bytecode_one_word() {
    let byte_array: Array<u8> = array![
        0x01,
        0x02,
        0x03,
        0x04,
        0x05,
        0x06,
        0x07,
        0x08,
        0x09,
        0x0A,
        0x0B,
        0x0C,
        0x0D,
        0x0E,
        0x0F,
        0x10,
        0x11,
        0x12,
        0x13,
        0x14,
        0x15,
        0x16,
        0x17,
        0x18,
        0x19,
        0x1A,
        0x1B,
        0x1C,
        0x1D,
        0x1E,
        0x1F, // 31 elements
    ];
    let evm_address = EVM_ADDRESS();
    let mut ca = ContractAccountTrait::new(evm_address);
    ca.store_bytecode(byte_array.span());

    // Address at which the bytecode should be stored
    let data_addr = compute_storage_base_address(
        selector!("contract_account_bytecode"), array![evm_address.into()].span()
    );
    let pending_word_addr = storage_base_address_from_felt252(data_addr.into() - 2_felt252);
    let pending_word_len_addr = storage_base_address_from_felt252(data_addr.into() - 1_felt252);

    let pending_word = Store::<felt252>::read(0, pending_word_addr).unwrap();
    let pending_word_len = Store::<u32>::read(0, pending_word_len_addr).unwrap();
    let list: List<bytes31> = Store::<List<bytes31>>::read(0, data_addr).unwrap();
    let bytecode: ByteArray = ByteArray {
        data: list.array(), pending_word: pending_word, pending_word_len: pending_word_len
    };

    assert(bytecode.pending_word_len == 0, 'pending word len not empty');
    assert(bytecode.pending_word == 0, 'pending word not empty');
    let mut i: u32 = 0;
    loop {
        if i == byte_array.len() {
            break;
        }
        assert(bytecode[i] == *byte_array[i], 'stored bytecode error');
        i += 1;
    }
}

#[test]
#[available_gas(20000000)]
fn test_store_bytecode_one_word_pending() {
    let byte_array: Array<u8> = array![
        0x01,
        0x02,
        0x03,
        0x04,
        0x05,
        0x06,
        0x07,
        0x08,
        0x09,
        0x0A,
        0x0B,
        0x0C,
        0x0D,
        0x0E,
        0x0F,
        0x10,
        0x11,
        0x12,
        0x13,
        0x14,
        0x15,
        0x16,
        0x17,
        0x18,
        0x19,
        0x1A,
        0x1B,
        0x1C,
        0x1D,
        0x1E,
        0x1F,
        0x20,
        0x21 // 33 elements
    ];
    let evm_address = EVM_ADDRESS();
    let mut ca = ContractAccountTrait::new(evm_address);
    ca.store_bytecode(byte_array.span());

    // Address at which the bytecode should be stored
    let data_addr = compute_storage_base_address(
        selector!("contract_account_bytecode"), array![evm_address.into()].span()
    );
    let pending_word_addr = storage_base_address_from_felt252(data_addr.into() - 2_felt252);
    let pending_word_len_addr = storage_base_address_from_felt252(data_addr.into() - 1_felt252);

    let pending_word = Store::<felt252>::read(0, pending_word_addr).unwrap();
    let pending_word_len = Store::<u32>::read(0, pending_word_len_addr).unwrap();
    let list: List<bytes31> = Store::<List<bytes31>>::read(0, data_addr).unwrap();
    let bytecode: ByteArray = ByteArray {
        data: list.array(), pending_word: pending_word, pending_word_len: pending_word_len
    };

    assert(bytecode.pending_word_len == 2, 'pending word len not two');
    assert(bytecode.pending_word == 0x2021, 'pending word not restituted');
    let mut i: u32 = 0;
    loop {
        if i == byte_array.len() {
            break;
        }
        assert(bytecode[i] == *byte_array[i], 'stored bytecode error');
        i += 1;
    }
}

#[test]
#[available_gas(20000000)]
fn test_load_bytecode() {
    let byte_array: Array<u8> = array![
        0x01,
        0x02,
        0x03,
        0x04,
        0x05,
        0x06,
        0x07,
        0x08,
        0x09,
        0x0A,
        0x0B,
        0x0C,
        0x0D,
        0x0E,
        0x0F,
        0x10,
        0x11,
        0x12,
        0x13,
        0x14,
        0x15,
        0x16,
        0x17,
        0x18,
        0x19,
        0x1A,
        0x1B,
        0x1C,
        0x1D,
        0x1E,
        0x1F,
        0x20,
        0x21 // 33 elements
    ];
    let evm_address = EVM_ADDRESS();
    let mut ca = ContractAccountTrait::new(evm_address);
    ca.store_bytecode(byte_array.span());
    let bytecode = ca.load_bytecode().unwrap();
    let mut i: u32 = 0;
    loop {
        if i == byte_array.len() {
            break;
        }
        assert(bytecode[i] == *byte_array[i], 'loaded bytecode error');
        i += 1;
    }
}

#[test]
#[available_gas(2000000)]
fn test_valid_jumps() {
    let evm_address = EVM_ADDRESS();
    let mut ca = ContractAccountTrait::new(evm_address);
    assert(!ca.is_valid_jump(10).unwrap(), 'should default false');
    ca.set_valid_jump(10);
    assert(ca.is_valid_jump(10).unwrap(), 'should be true')
}
//TODO add a test with huge amount of bytecode - using SNFoundry and loading data from txt

