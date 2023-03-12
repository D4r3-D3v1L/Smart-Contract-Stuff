use dotenv::dotenv;
use ethers::prelude::*;
use ethers::utils::hex;
use mongodb::{Client, Collection};
use std::convert::TryFrom;
use std::env;
use std::fs::{File, OpenOptions};
use std::io::Write;
use std::path::Path;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Load the .env file
    dotenv().ok();

    // Get the values of the environment variables
    let project_id = env::var("PROJECT_ID").expect("PROJECT_ID not found in .env");
    let target_amount = env::var("TARGET_AMOUNT").expect("TARGET_AMOUNT not found in .env");
    let target_amount = U256::from_dec_str(&target_amount).unwrap();

    // Connect to the Ethereum network using Infura
    let provider =
        Provider::<Http>::try_from(format!("https://goerli.infura.io/v3/{}", project_id))?;
    let mut block_stream = provider.watch_blocks().await?;

    while let Some(block) = block_stream.next().await {
        let block_header = provider.get_block_with_txs(block).await?;

        if let Some(block_header) = block_header {
            let txns = block_header.transactions;
            for txn in txns {
                let from = format_address(txn.from);
                let to = format_address(txn.from);
                let hash = format!("0x{}", hex::encode(txn.hash));
                let value = txn.value;

                if value > target_amount {
                    let txn_string = format!(
                        "Transaction Hash: {}, from: {}, to: {}, value: {}\n",
                        hash, from, to, value
                    );

                    let file_name = format!("block_{}.txt", block_header.number.unwrap().as_u64());
                    let path = Path::new(&file_name);

                    // Open the file in append mode
                    let mut file = OpenOptions::new()
                        .create(true)
                        .append(true)
                        .open(&path)
                        .unwrap();

                    file.write_all(txn_string.as_bytes())?;
                    println!("{}", txn_string);
                }
            }
        }
    }

    Ok(())
}

fn format_address(address: H160) -> String {
    format!("0x{}", hex::encode(address.as_fixed_bytes()))
}
