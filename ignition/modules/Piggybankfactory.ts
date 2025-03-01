import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("PiggyBankFactoryModule", (m) => {
  // Deploy the PiggyBankFactory contract
  const piggyBankFactory = m.contract("PiggyBankFactory");

  return { piggyBankFactory };
});
