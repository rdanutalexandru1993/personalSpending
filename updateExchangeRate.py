from forex_python.converter import CurrencyRates
from datetime import datetime
import datetime
import pandas as pd
import numpy as np

class updateExchangeRates():
    def __init__(self, URL):
        self.link = URL

    def loadCsv(self):
        print('Loading data ...')
        self.data = pd.read_csv(r'/media/alex/cf35aee0-faeb-40bb-adac-88595e8f71fe/alex_hdd/crtFolder/2022/personal_spending/spending.csv')

    def getDistinctCurrencies(self):
        print('Extracting unique currencies ...')
        self.distinctCrncy = self.data['fromCurrency'].unique().tolist()

    def setBaseCurrency(self):
        self.baseCurrency = (self.data['baseCurrency'].unique())[0]
        print('Set base currency to: ' + self.baseCurrency)

    def updateExchageRateWhereSameCurrency(self):
        self.data['exchangeRate'] = np.where(self.data['fromCurrency'] == 'GBP', 1, self.data['exchangeRate'])

    def extCurrencyAndDates(self):
        toExtract = self.data[self.data['exchangeRate'].isnull()][['fromCurrency', 'baseCurrency', 'date']]
        toExtract = toExtract.drop_duplicates()
        cRates = CurrencyRates()
        for index,row in toExtract.iterrows():
            fromCurrency = row['fromCurrency']
            baseCurrency = row['baseCurrency']
            dtString = row['date']
            dt = datetime.datetime.strptime(dtString, '%Y-%m-%d')

            indexWhereToChange = self.data[(self.data['date'] == dtString) &
                                           (self.data['fromCurrency'] == fromCurrency) &
                                           (self.data['baseCurrency'] == baseCurrency)].index

            try:
                eRate = cRates.get_rate(baseCurrency, fromCurrency, dt)
                print('Extracted exchange rate for ' + baseCurrency + '/' + fromCurrency + ' at ' + dtString + ': ' + str(eRate))

                for i in indexWhereToChange:
                    print('Updating index ' + str(i))
                    self.data.at[i, 'exchangeRate'] = eRate
            except:
                print('Failed to extract exchange rate for ' + baseCurrency + '/' + fromCurrency + ' at ' + dtString)

    def returnDataFrame(self):
        return self.data

    def updateCurrencies(self):
        self.loadCsv()
        self.getDistinctCurrencies()
        self.setBaseCurrency()
        self.updateExchageRateWhereSameCurrency()
        self.extCurrencyAndDates()
        self.returnDataFrame()

def main():
  p1 = updateExchangeRates('/media/alex/cf35aee0-faeb-40bb-adac-88595e8f71fe/alex_hdd/crtFolder/2022/personal_spending/spending.csv')
  p1.updateCurrencies()
  data = p1.data
  data.to_csv('/media/alex/cf35aee0-faeb-40bb-adac-88595e8f71fe/alex_hdd/crtFolder/2022/personal_spending/spendingWCurrencies.csv')

if __name__ == '__main__':
    main()





