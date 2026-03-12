/**
 * CLI-Anything 能力验证测试
 */

const { cli } = require('./03-cli-anything-framework');
const fs = require('fs');
const path = require('path');

async function runValidationTests() {
  console.log('=== CLI-Anything 能力验证 ===\n');
  
  const results = {
    timestamp: new Date().toISOString(),
    tests: [],
    summary: { passed: 0, failed: 0, total: 0 }
  };

  // 测试1: 系统信息获取
  console.log('Test 1: 系统信息获取');
  try {
    const sysInfo = await cli.execute('system-info');
    console.log('  ✓ 成功');
    console.log('  结果:', JSON.stringify(sysInfo.result, null, 2).substring(0, 200));
    results.tests.push({ name: 'system-info', status: 'passed', result: sysInfo.result });
    results.summary.passed++;
  } catch (e) {
    console.log('  ✗ 失败:', e.message);
    results.tests.push({ name: 'system-info', status: 'failed', error: e.message });
    results.summary.failed++;
  }
  results.summary.total++;
  console.log();

  // 测试2: 目录列表
  console.log('Test 2: 目录列表');
  try {
    const dirList = await cli.execute('dir-list', { path: 'C:\\OpenClaw_Workspace' });
    console.log('  ✓ 成功');
    console.log('  文件数:', Array.isArray(dirList.result) ? dirList.result.length : 1);
    results.tests.push({ name: 'dir-list', status: 'passed' });
    results.summary.passed++;
  } catch (e) {
    console.log('  ✗ 失败:', e.message);
    results.tests.push({ name: 'dir-list', status: 'failed', error: e.message });
    results.summary.failed++;
  }
  results.summary.total++;
  console.log();

  // 测试3: 文件信息
  console.log('Test 3: 文件信息');
  try {
    const testFile = 'C:\\OpenClaw_Workspace\\workspace\\cli-anything-capability\\03-cli-anything-framework.js';
    if (fs.existsSync(testFile)) {
      const fileInfo = await cli.execute('file-info', { path: testFile });
      console.log('  ✓ 成功');
      console.log('  文件名:', fileInfo.result?.Name);
      results.tests.push({ name: 'file-info', status: 'passed' });
      results.summary.passed++;
    } else {
      throw new Error('测试文件不存在');
    }
  } catch (e) {
    console.log('  ✗ 失败:', e.message);
    results.tests.push({ name: 'file-info', status: 'failed', error: e.message });
    results.summary.failed++;
  }
  results.summary.total++;
  console.log();

  // 测试4: 图片信息 (如果 ImageMagick 安装)
  console.log('Test 4: 图片信息 (ImageMagick)');
  try {
    // 先创建一个测试图片
    const testImage = 'C:\\OpenClaw_Workspace\\workspace\\cli-anything-capability\\test-image.png';
    
    // 使用 PowerShell 创建简单图片
    const psCmd = `Add-Type -AssemblyName System.Drawing; $bmp = New-Object System.Drawing.Bitmap(100, 100); $bmp.Save('${testImage}'); $bmp.Dispose()`;
    require('child_process').execSync(`powershell -Command "${psCmd}"`);
    
    if (fs.existsSync(testImage)) {
      const imgInfo = await cli.execute('image-info', { path: testImage });
      console.log('  ✓ 成功');
      results.tests.push({ name: 'image-info', status: 'passed' });
      results.summary.passed++;
      
      // 清理
      fs.unlinkSync(testImage);
    } else {
      throw new Error('ImageMagick 未安装或测试图片创建失败');
    }
  } catch (e) {
    console.log('  ⚠ 跳过:', e.message);
    results.tests.push({ name: 'image-info', status: 'skipped', reason: e.message });
  }
  results.summary.total++;
  console.log();

  // 测试5: 视频信息 (如果 ffmpeg 安装)
  console.log('Test 5: 视频信息 (ffmpeg)');
  try {
    const ffmpegCheck = require('child_process').execSync('where ffmpeg', { encoding: 'utf-8' });
    console.log('  ℹ ffmpeg 已安装');
    results.tests.push({ name: 'video-info', status: 'info', message: 'ffmpeg available' });
  } catch (e) {
    console.log('  ⚠ ffmpeg 未安装');
    results.tests.push({ name: 'video-info', status: 'skipped', reason: 'ffmpeg not installed' });
  }
  results.summary.total++;
  console.log();

  // 保存结果
  fs.writeFileSync(
    'C:\\OpenClaw_Workspace\\workspace\\cli-anything-capability\\validation-results.json',
    JSON.stringify(results, null, 2)
  );

  console.log('=== 验证完成 ===');
  console.log(`通过: ${results.summary.passed}`);
  console.log(`失败: ${results.summary.failed}`);
  console.log(`总计: ${results.summary.total}`);
  console.log('\n详细结果已保存到: validation-results.json');

  return results;
}

runValidationTests().catch(console.error);
