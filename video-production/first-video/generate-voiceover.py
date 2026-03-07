import edge_tts
import asyncio
import os
import sys

# 设置输出编码为 UTF-8
sys.stdout.reconfigure(encoding='utf-8')

# 配音脚本（分段）
segments = {
    "01_opening": """
What's up, traders! You're about to see something incredible. 
My semi-automated box strategy just completed Day 1, and the results are amazing. 
Let's dive in!
""",
    
    "02_overview": """
Today was an incredible day in the markets. 
My strategy identified 5 high-probability setups. 
Out of these 5 trades, 4 were winners and 1 was a loser, giving us a win rate of 80%. 
The total profit for today is 250 dollars. 
Now let me show you exactly how it happened.
""",
    
    "03_strategy": """
For those new to the channel, here's how the box strategy works. 
The strategy identifies consolidation zones, or boxes, where price is ranging between support and resistance. 
When price breaks out with strong momentum, that's our entry signal. 
It's semi-automated: I draw the boxes manually, but the EA handles everything else. 
This gives us the best of both worlds.
""",
    
    "04_trade1": """
Let's start with Trade Number 1. 
This was on EURUSD on the H1 timeframe. 
I spotted a perfect box formation between 1.38 and 1.40. 
Price broke above the box at 1.39, and I entered long. 
My stop loss was at 1.385, take profit at 1.395. 
The trade went perfectly. 
Price hit my take profit in just 75 minutes, for a profit of 50 pips, which is 125 dollars. 
This is exactly what we're looking for.
""",
    
    "05_trade2": """
Trade 2 was on GBPUSD, another winner, plus 75 dollars.
""",
    
    "06_trade3": """
Trade 3 on USDCHF, this one hit my stop loss, minus 50 dollars. 
Not every trade is a winner, and that's okay.
""",
    
    "07_trade4": """
Trade 4 on XAUUSD, big winner, plus 100 dollars. 
So out of 4 trades, 3 winners, 1 loser. 
That's a 75% win rate, and we're up 250 dollars for the day.
""",
    
    "08_settings": """
Now, let me show you the EA settings. 
Base risk is 1%, very conservative. 
ATR stop loss multiplier is 2.0 for dynamic stops. 
Maximum martingale is 2, for controlled risk. 
These settings have been optimized over months of testing. 
If you want to use this strategy yourself, check out the links in the description.
""",
    
    "09_cta": """
So that's Day 1! 250 dollars profit, 80% win rate. 
If you want to use this strategy, I have two options: 
TradingView signals for real-time alerts, or the semi-automated EA for MT5. 
Both links are in the description. 
Don't forget to subscribe, hit the like button, and leave a comment. 
See you tomorrow with Day 2 results!
"""
}

async def generate_voiceover(text, output_file, voice="en-US-GuyNeural"):
    """生成配音"""
    communicate = edge_tts.Communicate(text, voice)
    await communicate.save(output_file)
    print(f"✓ 生成: {output_file}")

async def main():
    print("=== 开始生成AI配音 ===")
    print()
    
    # 创建音频目录
    audio_dir = r"C:\OpenClaw_Workspace\workspace\video-production\first-video\audio"
    os.makedirs(audio_dir, exist_ok=True)
    
    # 使用英文男声（Guy - 友好、专业）
    voice = "en-US-GuyNeural"
    
    print(f"使用声音: {voice}")
    print()
    
    # 生成所有片段
    for segment_id, text in segments.items():
        output_file = os.path.join(audio_dir, f"segment_{segment_id}.mp3")
        await generate_voiceover(text, output_file, voice)
    
    print()
    print("=== 所有配音生成完成 ===")
    print()
    print("生成的文件:")
    for file in sorted(os.listdir(audio_dir)):
        if file.endswith('.mp3'):
            file_path = os.path.join(audio_dir, file)
            size = os.path.getsize(file_path) / 1024
            print(f"  - {file} ({size:.2f} KB)")

if __name__ == "__main__":
    asyncio.run(main())
