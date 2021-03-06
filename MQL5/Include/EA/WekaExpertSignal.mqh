//+------------------------------------------------------------------+
//|                                             WekaExpertSignal.mqh |
//|                                                         Zephyrrr |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Zephyrrr"
#property link      "http://www.mql5.com"

#include <ExpertModel\ExpertModel.mqh>
#include <ExpertModel\ExpertModelSignal.mqh>
#include <ExpertModel\Money\MoneyFixedLot.mqh>

#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\DealInfo.mqh>

#include <Indicators\Oscilators.mqh>
#include <Indicators\TimeSeries.mqh>

#include <Files\FileTxt.mqh>
#include <Weka\WekaExpert.mqh>
#include <Utils\IsNewBar.mqh>

class CWekaExpertSignal : public CExpertModelSignal
{
private:
    CWekaExpert* m_wekaExpert;

    char m_dealType;
    int m_dealTp, m_dealSl;
    bool m_needRebuildModel;
    
    CisNewBar m_isNewBarH1, m_isNewBarM5;
public:
	CWekaExpertSignal();
	~CWekaExpertSignal();
	virtual bool      ValidationSettings();
	virtual bool      InitIndicators(CIndicators* indicators);

	virtual bool      CheckOpenLong(double& price,double& sl,double& tp,datetime& expiration);
	virtual bool      CheckCloseLong(CTableOrder* t, double& price);
	virtual bool      CheckOpenShort(double& price,double& sl,double& tp,datetime& expiration);
	virtual bool      CheckCloseShort(CTableOrder* t, double& price);

	void InitParameters();
};

void CWekaExpertSignal::InitParameters()
{
    m_isNewBarH1.SetSymbol(m_symbol.Name());
    m_isNewBarH1.SetPeriod(PERIOD_H1);
    m_isNewBarM5.SetSymbol(m_symbol.Name());
    m_isNewBarM5.SetPeriod(PERIOD_M30);
}

void CWekaExpertSignal::CWekaExpertSignal()
{
    m_dealType = '0';
    m_needRebuildModel = true;
}

void CWekaExpertSignal::~CWekaExpertSignal()
{
    delete m_wekaExpert;
}
bool CWekaExpertSignal::ValidationSettings()
{
	if(!CExpertSignal::ValidationSettings()) 
		return(false);

	if(false)
	{
		printf(__FUNCTION__+": Indicators should not be Null!");
		return(false);
	}
	
	return(true);
}

bool CWekaExpertSignal::InitIndicators(CIndicators* indicators)
{
	if(indicators==NULL) 
		return(false);
	bool ret = true;

    m_wekaExpert = new CWekaExpert(m_symbol.Name());
    if (m_needRebuildModel)
    {
        m_wekaExpert.BuildModel();
        m_needRebuildModel = false;
    }
    
	return ret;
}


bool CWekaExpertSignal::CheckOpenLong(double& price,double& sl,double& tp,datetime& expiration)
{
    Debug("CWekaExpertSignal::CheckOpenLong");
    
    if (m_needRebuildModel)
    {
        m_wekaExpert.BuildModel();
        m_needRebuildModel = false;
    }
    else
    {
        if (m_isNewBarH1.isNewBar())
        {
            m_needRebuildModel = true;
        }
    }
    
    if (!m_isNewBarM5.isNewBar())
    {
        m_dealType = '0';
        m_dealTp = 0;
        m_dealSl = 0;
        return false;
    }
    
    string r = m_wekaExpert.Predict();
    
    if (r == NULL || r == "")
    {
        Notice("Get predict value of null at ", TimeToString(TimeCurrent()));
        return false;
    }
    Notice("Get predict value of ", r, " at ", TimeToString(TimeCurrent()));    
    m_dealType = (char)StringGetCharacter(r, 0);
    int idx1=2, idx2 = 2;
    string s = GetSubString(r, idx1, idx2, "_");
    m_dealTp = (int)StringToInteger(s);
    s = GetSubString(r, idx1, idx2, "_");
    m_dealSl = (int)StringToInteger(s);
    s = GetSubString(r, idx1, idx2, "_");
    double v = StringToDouble(s);
    
	CExpertModel* em = (CExpertModel *)m_expert;
	//if (em.GetOrderCount(ORDER_TYPE_BUY) >= 1)
	//	return false;
    //((CMoneyFixedLot *)em.ExpertModelMoney()).Lots(v);
    
	if (m_dealType == 'B')
	{
		m_symbol.RefreshRates();

		price = m_symbol.Ask();
		tp = price + m_dealTp * m_symbol.Point() * GetPointOffset(m_symbol.Digits());
		sl = price - m_dealSl * m_symbol.Point() * GetPointOffset(m_symbol.Digits());
		
		return true;
	}

	return false;
}

bool CWekaExpertSignal::CheckOpenShort(double& price,double& sl,double& tp,datetime& expiration)
{
    Debug("CWekaExpertSignal::CheckOpenShort");

	CExpertModel* em = (CExpertModel *)m_expert;
	//if (em.GetOrderCount(ORDER_TYPE_SELL) >= 1)
	//	return false;
        
	if (m_dealType == 'S')
	{
		m_symbol.RefreshRates();

		price = m_symbol.Bid();
		tp = price - m_dealTp * m_symbol.Point() * GetPointOffset(m_symbol.Digits());
		sl = price + m_dealSl * m_symbol.Point() * GetPointOffset(m_symbol.Digits());

		return true;
	}

	return false;
}

bool CWekaExpertSignal::CheckCloseLong(CTableOrder* t, double& price)
{
	return false;
}

bool CWekaExpertSignal::CheckCloseShort(CTableOrder* t, double& price)
{
    return false;
}
