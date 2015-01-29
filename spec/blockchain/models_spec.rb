# encoding: ascii-8bit

require_relative '../spec_helper'

include Bitcoin
include Bitcoin::Blockchain

Bitcoin::network = :testnet
[
  [:dummy],
  [:archive, :sqlite],
  # [:utxo, :sqlite, index_all_addrs: true],
  [:archive, :postgres],
  # [:utxo, :postgres, index_all_addrs: true],
  [:archive, :mysql],
  # [:utxo, :mysql, index_all_addrs: true],
].compact.each do |options|

  describe "Blockchain::Models (#{options[0].to_s.capitalize}Store, #{options[1]})" do

    before(:all) { skip  unless @store = setup_db(*options) }

    before do
      Bitcoin.network[:no_difficulty] = true
      Bitcoin.network[:proof_of_work_limit] = Bitcoin.encode_compact_bits("ff"*32)

      def @store.in_sync?; true; end
      @store.reset

      @store.store_block(P::Block.new(fixtures_file('testnet/block_0.bin')))
      @store.store_block(P::Block.new(fixtures_file('testnet/block_1.bin')))
      @store.store_block(P::Block.new(fixtures_file('testnet/block_2.bin')))
      @store.store_block(P::Block.new(fixtures_file('testnet/block_3.bin')))

      unless @store.backend_name == "utxo"
        @store.store_tx(P::Tx.new(fixtures_file('rawtx-01.bin')), false)
        @store.store_tx(P::Tx.new(fixtures_file('rawtx-02.bin')), false)
      end

      @blk = P::Block.new(fixtures_file('testnet/block_4.bin'))
      @tx = P::Tx.new(fixtures_file('rawtx-03.bin'))
    end

    after do
      Bitcoin.network.delete :no_difficulty
    end

    describe "Block" do

      let(:block) { @store.get_block_by_depth(1) }

      it "should get prev block" do
        block.get_prev_block.should == @store.get_block_by_depth(0)
      end

      it "should get next block" do
        block.get_next_block.should == @store.get_block_by_depth(2)
      end

      it "should get total out" do
        block.total_out.should == 5000000000
      end

      it "should get total in" do
        block.total_in.should == 5000000000
      end

      it "should get total fee" do
        block.total_fee.should == 0
      end

    end

    describe "Tx" do

      let(:tx) { @store.get_block_by_depth(1).tx[0] }

      it "should get block" do
        tx.get_block.should == @store.get_block_by_depth(1)
      end

      it "should get confirmations" do
        tx.confirmations.should == 3
      end

      it "should get total out" do
        tx.total_out.should == 5000000000
      end

      it "should get total in" do
        tx.total_in.should == 5000000000
      end

      it "should get fee" do
        tx.fee.should == 0
      end

    end

  end

end
