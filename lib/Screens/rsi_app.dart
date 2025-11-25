import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main(){
  runApp(const StockRSIScreen());
}

class StockRSIScreen extends StatefulWidget {
  const StockRSIScreen({Key? key}) : super(key: key);

  @override
  State<StockRSIScreen> createState() => _StockRSIScreenState();
}

class _StockRSIScreenState extends State<StockRSIScreen> {
  // Example list — replace with your 50 symbols
  List<String> symbols = [
    'RELIANCE',
    'TCS',
    'INFY',
    'ICICIBANK',
    'HDFCBANK',
    'SBIN',
    'ITC',
    'WIPRO',

  ];

  List<Map<String, dynamic>> topRsiList = [];
  bool isLoading = false;

  Future<void> fetchRSIData() async {
    setState(() {
      isLoading = true;
      topRsiList.clear();
    });

    const apiKey = "aba02ca28cda41a2b653f743bfd6a11e"; // Replace with your real key

    for (final symbol in symbols) {
      final url = Uri.parse(
        "https://api.twelvedata.com/rsi?symbol=$symbol&interval=1day&apikey=$apiKey"
        // "https://api.twelvedata.com/rsi?symbol=.NSE&interval=1day&time_period=14&apikey=$",
      );

      try {
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['status'] == 'ok' && data['values'] != null) {
            final latestRSI = double.parse(data['values'].first['rsi']);

            if (latestRSI > 50) {
              topRsiList.add({
                'symbol': symbol,
                'rsi': latestRSI,
              });
            }
          }
        }
      } catch (e) {
        print("❌ Error for $symbol: $e");
      }

      // Small delay to avoid free plan rate-limit
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // Sort by RSI descending (highest first)
    topRsiList.sort((a, b) => b['rsi'].compareTo(a['rsi']));

    // Keep only top 20
    if (topRsiList.length > 20) {
      topRsiList = topRsiList.sublist(0, 20);
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Top 20 Stocks (RSI > 50)")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: fetchRSIData,
                child: const Text("Fetch RSI Data"),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const CircularProgressIndicator()
              else if (topRsiList.isEmpty)
                const Text("No stocks found or not checked yet.")
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: topRsiList.length,
                    itemBuilder: (context, index) {
                      final stock = topRsiList[index];
                      return ListTile(
                        leading: const Icon(Icons.trending_up, color: Colors.green),
                        title: Text(stock['symbol']),
                        trailing: Text(
                          "RSI: ${stock['rsi'].toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}



// 200 Nifty
//'LTF',
//     'BSE',
//     'SHRIRAMFIN',
//     'IDEA',
//     'PREMIERENE',
//     'POWERINDIA',
//     'LICI',
//     'BANKINDIA',
//     'ABCAPITAL',
//     'AUBANK',
//     'BAJFINANCE',
//     'ADANIENT',
//     'TATASTEEL',
//     'BRITANNIA',
//     'VOLTAS',
//     'BAJAJFINSV',
//     'MFSL',
//     'UPL',
//     'JINDALSTEL',
//     'VEDL',
//     'UNIONBANK',
//     'SAIL',
//     'HDFCLIFE',
//     'M&MFIN',
//     'PAYTM',
//     'M&M',
//     'BPCL',
//     'COCHINSHIP',
//     'HUDCO',
//     'NATIONALUM',
//     'POLICYBZR',
//     'ICICIBANK'
//     'SBILIFE',
//     'HINDZINC',
//     'SOLARINDS',
//     'BHEL',
//     'PNB',
//     'MAZDOCK',
//     'NMDC',
//     'SONACOMS',
//     'INDUSINDBK',
//     'BEL',
//     'ENRIN',
//     'NAUKRI',
//     'GMRAIRPORT',
//     'MUTHOOTFIN',
//     'VMM',
//     'IDFCFIRSTB',
//     'EICHERMOT',
//     'CANBK',
//     'IRFC',
//     'YESBANK',
//     'FORTIS',
//     'GAIL',
//     'BANKBARODA',
//     'CHOLAFIN',
//     'APLAPOLLO',
//     'MAXHEALTH',
//     'INDIANB',
//     'PHOENIXLTD',
//     'GRASIM',
//     'IREDA',
//     'ZYDUSLIFE',
//     'UNITDSPR',
//     'HDFCAMC',
//     'MRF',
//     'ADANIPORTS',
//     'HAL',
//     'ICICIGI',
//     'KEI',
//     'TORNTPHARM',
//     'INFY',
//     'COALINDIA',
//     'MOTILALOFS',
//     'ACC',
//     'FEDERALBNK',
//     'LUPIN',
//     'GLENMARK',
//     'NTPC',
//     'IGL',
//     'TVSMOTOR',
//     'RECLTD',
//     'PRESTIGE',
//     'HINDPETRO',
//     'TATAPOWER',
//     'TORNTPOWER',
//     'POWERGRID',
//     'CIPLA',
//     'BDL',
//     'HAVELLS',
//     'JIOFIN',
//     'PATANJALI',
//     'CONCOR',
//     'PIIND',
//     'ALKEM',
//     'JSWSTEEL',
//     'INDUSTOWER',
//     'TATACOMM',
//     'SUNPHARMA',
//     'ONGC',
//     'TIINDIA',
//     'OBEROIRLTY',
//     'RVNL',
//     'ASIANPAINT',
//     'MOTHERSON',
//     'KOTAKBANK',
//     'IOC',
//     'CGPOWER',
//     'PIDILITIND',
//     'HINDALCO',
//     'LICHSGFIN',
//     'MARUTI',
//     'JSWENERGY',
//     'GODFRYPHLP',
//     'OIL',
//     'KALYANKJIL',
//     'DRREDDY',
//     'IRCTC',
//     'ETERNAL',
//     'AMBUJACEM',
//     'ASHOKLEY',
//     'BAJAJHFL',
//     'DLF',
//     'SRF',
//     'LT',
//     'HINDUNILVR',
//     'SBICARD',
//     'PAGEIND',
//     'HDFCBANK',
//     'BAJAJ-AUTO',
//     'COROMANDEL',
//     'NYKAA',
//     'VBL',
//     'ADANIGREEN',
//     'TITAN',
//     'BHARATFORG',
//     'SHREECEM',
//     'ADANIENSOL',
//     '360ONE',
//     'NESTLEIND',
//     'COLPAL',
//     'TATATECH',
//     'AXISBANK',
//     'SUPREMEIND',
//     'DABUR',
//     'KPITTECH',
//     'MARICO',
//     'LODHA',
//     'SWIGGY',
//     'HEROMOTOCO',
//     'ULTRACEMCO',
//     'TMPV',
//     'ASTRAL',
//     'TCS',
//     'BOSCHLTD',
//     'CUMMINSIND',
//     'SBIN',
//     'POLYCAB',
//     'EXIDEIND',
//     'NTPCGREEN',
//     'ITC',
//     'INDHOTEL',
//     'ATGL',
//     'IRB',
//     'PERSISTENT',
//     'ADANIPOWER',
//     'HCLTECH',
//     'RELIANCE',
//     'HYUNDAI',
//     'JUBLFOOD',
//     'TATAELXSI',
//     'TRENT',
//     'COFORGE',
//     'BIOCON',
//     'LTIM',
//     'WIPRO',
//     'GODREJCP',
//     'MPHASIS',
//     'ITCHOTELS',
//     'DIXON',
//     'INDIGO',
//     'AUROPHARMA',
//     'NHPC',
//     'OFSS',
//     'DMART',
//     'BLUESTARCO',
//     'SIEMENS',
//     'MANKIND',
//     'APOLLOHOSP',
//     'TECHM',
//     'TATACONSUM',
//     'GODREJPROP',
//     'PFC',
//     'WAAREEENER',
//     'BHARTIHEXA',
//     'SUZLON',
//     'BAJAJHLDNG',
//     'DIVISLAB',
//     'ABB',
//     'BHARTIARTL',