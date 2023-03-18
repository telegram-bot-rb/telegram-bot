RSpec.describe Telegram::Bot::AllowedSubnetsConstraint do
  subject(:constraint) { described_class.new(production_mode: true) }

  it 'allows traffic from telegram subnets' do
    expect(constraint).to be_matches(double('request', remote_ip: '91.108.6.127'))
    expect(constraint).to be_matches(double('request', remote_ip: '149.154.160.35'))
  end

  it 'does not allow traffic from a random IP' do
    expect(constraint).to_not be_matches(double('request', remote_ip: '13.56.126.253'))
  end
end
