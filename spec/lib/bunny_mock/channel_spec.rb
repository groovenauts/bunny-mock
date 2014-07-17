# -*- coding: utf-8 -*-
require 'spec_helper'
require 'bunny_mock'

describe BunnyMock::Channel do
  describe "#queue" do
    let(:channel) { BunnyMock::Channel.new }
    subject{ channel }
    context 'not set attrs' do
      it 'queue count' do
        subject.queue('queue1')
        expect(subject.queues.size).to eq(1)
      end

      it 'queue name' do
        subject.queue('queue1')
        expect(subject.queues.first.name).to  eq('queue1')
        expect(subject.queues.first.attrs).to eq({})
      end
    end

    context 'set attrs' do
      it 'queue count' do
        subject.queue('queue1', no_declare: true)
        expect(subject.queues.size).to eq(1)
      end

      it 'queue name' do
        subject.queue('queue1', no_declare: true)
        expect(subject.queues.first.name).to  eq('queue1')
        expect(subject.queues.first.attrs).to eq(no_declare: true)
      end
    end
  end
end
