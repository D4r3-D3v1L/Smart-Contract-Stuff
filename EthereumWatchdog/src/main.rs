use std::convert::TryFrom;
use std::path::Path;
use ethers::utils::hex;
use mongodb::{Client, Collection};
use ethers::prelude::*;
use std::fs::{File, OpenOptions};
use std::io::Write;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Connect to the Ethereum network using Infura
    let provider = Provider::<Http>::try_from("https://goerli.infura.io/v3/c60b0bb42f8a4c6481ecd229eddaca27")?;
    let block_stream = provider.watch_blocks().await?;

    // Loop through new block events
    block_stream.for_each(|block| async {

        // let block_number = block.number.unwrap().as_u64();
        // println!("New block: {}", block_number);

        // // Get the list of transactions in the new block
        // let txns = block.transactions.unwrap_or_default();
		let latest_block = provider.get_block(BlockNumber::Latest).await.unwrap().unwrap();

		let txns = latest_block.transactions.iter();
        // Check each transaction to see if it meets the specified criteria
        for txn in txns {
            let txn_hash = txn.clone();
            let txn_data = provider.get_transaction(txn_hash).await.unwrap().unwrap();

            let from = format_address(txn_data.from);
            let to = match txn_data.to {
                Some(to) => format_address(to),
                None => "None".to_string(),
            };
            let value = txn_data.value.as_u128();
			let txn_string = format!("Transaction Hash: {}, from: {}, to: {}, value: {}\n", txn_hash, from, to, value);

			let file_name = format!("block_{}.txt", latest_block.number.unwrap().as_u64());
            let path = Path::new(&file_name);

            // Open the file in append mode
            let mut file = OpenOptions::new()
                .create(true)
                .append(true)
                .open(&path)
                .unwrap();

            file.write_all(txn_string.as_bytes());
            println!("{}",txn_string);
        }
        
    }).await;

    Ok(())
}

fn format_address(address : H160)-> String {
	format!("0x{}", hex::encode(address.as_fixed_bytes()))
}
